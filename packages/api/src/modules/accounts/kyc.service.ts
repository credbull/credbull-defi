import { CredbullKYCProvider__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import * as _ from 'lodash';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';

import { KYCStatus, WhitelistAccountDto } from './kyc.dto';

@Injectable()
export class KycService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
    private readonly supabaseAdmin: SupabaseAdminService,
  ) {}

  async status(): Promise<ServiceResponse<KYCStatus>> {
    const client = this.supabase.client();

    const events = await client.from('kyc_events').select().eq('event_name', 'accepted').single();
    if (events.error) return events;

    if (!events.data?.address) return { data: KYCStatus.PENDING };

    const kycProvider = await client.from('vault_entities').select('*').eq('type', 'kyc_provider');
    if (kycProvider.error) return kycProvider;

    const distinctProviders = _.uniqBy(kycProvider.data ?? [], 'address');

    const check = await this.checkOnChain(distinctProviders, events.data?.address);
    if (check.error) return check;

    return check.data ? { data: KYCStatus.ACTIVE } : { data: KYCStatus.REJECTED };
  }

  async whitelist(dto: WhitelistAccountDto): Promise<ServiceResponse<Tables<'kyc_events'>[]>> {
    const admin = this.supabaseAdmin.admin();

    const wallet = await admin
      .from('user_wallets')
      .select()
      .eq('address', dto.address)
      .eq('user_id', dto.user_id)
      .single();
    if (wallet.error) return wallet;

    const query = admin.from('vault_entities').select('address').eq('type', 'kyc_provider');
    if (wallet.data.discriminator) {
      query.eq('tenant', dto.user_id);
    } else {
      query.is('tenant', null);
    }

    const providers = await query;
    if (providers.error) return providers;

    const errors = [];
    const distinctProviders = _.uniqBy(providers.data ?? [], 'address');

    for (const { address } of distinctProviders) {
      const provider = await this.getOnChainProvider(address);
      const { error, data } = await responseFromRead(provider, provider.status(dto.address));
      if (error) {
        errors.push(error);
        continue;
      }

      if (!data) {
        const { error } = await responseFromWrite(provider, provider.updateStatus([dto.address], [true]));
        if (error) errors.push(error);
      }
    }
    if (errors.length) return { error: new AggregateError(errors) };

    const existing = await admin
      .from('kyc_events')
      .select()
      .eq('address', dto.address)
      .eq('user_id', dto.user_id)
      .eq('event_name', 'accepted')
      .maybeSingle();

    if (existing.error) return existing;
    if (existing.data) return { data: [existing.data] };

    return admin
      .from('kyc_events')
      .insert({ ...dto, event_name: 'accepted' })
      .select();
  }

  private async checkOnChain(
    kycProviders: Tables<'vault_entities'>[],
    address: string,
  ): Promise<ServiceResponse<boolean>> {
    const errors = [];
    let status = false;

    for (const kyc of kycProviders) {
      const provider = await this.getOnChainProvider(kyc.address);
      const { error, data } = await responseFromRead(provider, provider.status(address));
      if (error) {
        errors.push(error);
        continue;
      }

      status = status && data;
      if (!status) break;
    }
    return errors.length > 0 ? { error: new AggregateError(errors) } : { data: status };
  }

  private async getOnChainProvider(address: string) {
    return CredbullKYCProvider__factory.connect(address, await this.ethers.operator());
  }
}
