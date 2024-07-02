import { CredbullWhiteListProvider__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import * as _ from 'lodash';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';

import { WhiteListAccountDto, WhiteListStatus } from './whiteList.dto';

@Injectable()
export class WhiteListService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
    private readonly supabaseAdmin: SupabaseAdminService,
  ) {}

  async status(): Promise<ServiceResponse<WhiteListStatus>> {
    const client = this.supabase.client();

    const events = await client.from('whitelist_events').select().eq('event_name', 'accepted').single();
    if (events.error) return events;

    if (!events.data?.address) return { data: WhiteListStatus.PENDING };

    const whiteListProvider = await client.from('vault_entities').select('*').eq('type', 'whitelist_provider');
    if (whiteListProvider.error) return whiteListProvider;

    const distinctProviders = _.uniqBy(whiteListProvider.data ?? [], 'address');

    const check = await this.checkOnChain(distinctProviders, events.data?.address);
    if (check.error) return check;

    return check.data ? { data: WhiteListStatus.ACTIVE } : { data: WhiteListStatus.REJECTED };
  }

  async whitelist(dto: WhiteListAccountDto): Promise<ServiceResponse<Tables<'whitelist_events'>[]>> {
    const admin = this.supabaseAdmin.admin();

    const wallet = await admin
      .from('user_wallets')
      .select()
      .eq('address', dto.address)
      .eq('user_id', dto.user_id)
      .single();
    if (wallet.error) return wallet;

    const query = admin.from('vault_entities').select('address').eq('type', 'whitelist_provider');
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
      .from('whitelist_events')
      .select()
      .eq('address', dto.address)
      .eq('user_id', dto.user_id)
      .eq('event_name', 'accepted')
      .maybeSingle();

    if (existing.error) return existing;
    if (existing.data) return { data: [existing.data] };

    return admin
      .from('whitelist_events')
      .insert({ ...dto, event_name: 'accepted' })
      .select();
  }

  private async checkOnChain(
    whiteListProviders: Tables<'vault_entities'>[],
    address: string,
  ): Promise<ServiceResponse<boolean>> {
    const errors = [];
    let status = false;

    for (const whiteListProvider of whiteListProviders) {
      const provider = await this.getOnChainProvider(whiteListProvider.address);
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
    return CredbullWhiteListProvider__factory.connect(address, await this.ethers.operator());
  }
}
