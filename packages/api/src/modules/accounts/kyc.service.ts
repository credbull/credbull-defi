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
    const { address } = dto;
    const client = this.supabase.admin();

    const wallet = await client.from('user_wallets').select().eq('address', address).single();
    if (wallet.error) return wallet;

    const vaults = await client.from('vaults').select('*').neq('status', 'created').lt('opened_at', 'now()');

    if (vaults.data) {
      for (const vault of vaults.data) {
        const vaultInstance = CredbullVault__factory.connect(vault.address, this.ethers.deployer());

        const { data } = await responseFromRead(vaultInstance.isWhitelisted(address));

        if (!data) {
          await responseFromWrite(vaultInstance.updateWhitelistStatus([address], [true]));
        }
      }
    }

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
}
