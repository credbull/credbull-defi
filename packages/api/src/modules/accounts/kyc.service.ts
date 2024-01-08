import { BadRequestException, Injectable } from '@nestjs/common';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';

import { KYCStatus } from './account-status.dto';

@Injectable()
export class KycService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
  ) {}

  async status(): Promise<KYCStatus> {
    const { data } = await this.supabase.client().from('kyc_events').select().eq('event_name', 'accepted').single();

    if (!data?.address) return KYCStatus.PENDING;

    return (await this.checkOnChain(data?.address)) //
      ? KYCStatus.ACTIVE
      : KYCStatus.REJECTED;
  }

  async whitelist(address: string): Promise<string> {
    const client = this.supabase.admin();

    const { error: selectError, data } = await client.from('user_wallets').select().eq('address', address).single();

    if (selectError) throw new BadRequestException(selectError.message);

    const { statusText, error: insertError } = await client.from('kyc_events').insert({
      address,
      user_id: data.user_id,
      event_name: 'accepted',
    });

    if (insertError) throw new BadRequestException(insertError.message);

    return statusText;
  }

  private async checkOnChain(address: string): Promise<boolean> {
    return Boolean(address);
  }
}
