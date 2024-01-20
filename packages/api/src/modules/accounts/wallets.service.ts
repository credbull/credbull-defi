import { Injectable } from '@nestjs/common';
import { SiweMessage } from 'siwe';

import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';

import { WalletDto } from './wallets.dto';

@Injectable()
export class WalletsService {
  constructor(private readonly supabase: SupabaseService) {}

  async link(dto: WalletDto): Promise<ServiceResponse<Tables<'user_wallets'>[]>> {
    const { message, signature } = dto;
    const supabase = this.supabase.client();

    const auth = await supabase.auth.getUser();
    if (auth.error) return { error: auth.error };

    const verify = await new SiweMessage(message).verify({ signature });
    if (verify.error) return { error: verify.error };

    const existing = await supabase.from('user_wallets').select().eq('address', verify.data.address).maybeSingle();
    if (existing.error) return { error: existing.error };
    if (existing.data) return { data: [existing.data] };

    return supabase
      .from('user_wallets')
      .insert({
        user_id: auth.data.user?.id,
        address: verify.data.address,
      })
      .select();
  }
}
