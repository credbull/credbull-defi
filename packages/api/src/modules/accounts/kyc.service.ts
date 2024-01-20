import { CredbullVault__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';

import { EthersService } from '../../clients/ethers/ethers.service';
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
  ) {}

  async status(): Promise<ServiceResponse<KYCStatus>> {
    const events = await this.supabase.client().from('kyc_events').select().eq('event_name', 'accepted').single();

    if (!events.data?.address) return { data: KYCStatus.PENDING };

    return (await this.checkOnChain(events.data?.address)) //
      ? { data: KYCStatus.ACTIVE }
      : { data: KYCStatus.REJECTED };
  }

  async whitelist(dto: WhitelistAccountDto): Promise<ServiceResponse<Tables<'kyc_events'>[]>> {
    const { address, user_id } = dto;
    const client = this.supabase.admin();

    const existing = await client
      .from('kyc_events')
      .select()
      .eq('address', address)
      .eq('user_id', user_id)
      .eq('event_name', 'accepted')
      .maybeSingle();

    if (existing.error) return existing;
    if (existing.data) return { data: [existing.data] };

    const wallet = await client.from('user_wallets').select().eq('address', address).eq('user_id', user_id).single();
    if (wallet.error) return wallet;

    const vaults = await client.from('vaults').select('*').neq('status', 'created').lt('opened_at', 'now()');
    if (vaults.error) return vaults;

    const errors = [];
    if (vaults.data) {
      for (const vault of vaults.data) {
        const vaultInstance = this.getVaultInstance(vault.address);
        const { error, data } = await responseFromRead(vaultInstance.isWhitelisted(address));
        if (error) {
          errors.push(error);
          continue;
        }

        if (!data) await responseFromWrite(vaultInstance.updateWhitelistStatus([address], [true]));
      }
    }
    if (errors.length) return { error: new AggregateError(errors) };

    return client
      .from('kyc_events')
      .insert({
        address,
        user_id: wallet.data.user_id,
        event_name: 'accepted',
      })
      .select();
  }

  private async checkOnChain(address: string): Promise<boolean> {
    return Boolean(address);
  }

  private getVaultInstance(address: string) {
    return CredbullVault__factory.connect(address, this.ethers.deployer());
  }
}
