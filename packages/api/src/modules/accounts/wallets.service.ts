import { Injectable } from '@nestjs/common';
import { SiweMessage } from 'siwe';

import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';

import { WalletDto } from './wallets.dto';

@Injectable()
export class WalletsService {
  constructor(private readonly supabase: SupabaseService) {}

  async link(dto: WalletDto): Promise<ServiceResponse<Tables<'user_wallets'>>> {
    const { message, signature } = dto;
    const supabase = this.supabase.client();

    const { error: authError, data: auth } = await supabase.auth.getUser();
    if (authError) return { error: authError };

    const { error: verifyError, data } = await new SiweMessage(message).verify({ signature });
    if (verifyError) return { error: verifyError };

    return supabase.from('user_wallets').insert({
      user_id: auth.user?.id,
      address: data.address,
    });
  }
}
