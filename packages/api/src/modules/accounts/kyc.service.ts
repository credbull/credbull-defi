import { Injectable } from '@nestjs/common';

import { MerkleTreeService } from '../../clients/merkletree/merkletree.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';

import { KYCStatus, WhitelistAccountDto } from './kyc.dto';

@Injectable()
export class KycService {
  // private tree: MerkleTreeService;
  constructor(
    private readonly supabase: SupabaseService,
    private readonly tree: MerkleTreeService,
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

    //this.tree.addLeaves([wallet.data.address]);

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

  async getProof(address: string): Promise<string[]> {
    return await this.tree.getProof(address);
  }

  async getRoot(): Promise<string> {
    return await this.tree.getRoot();
  }
}
