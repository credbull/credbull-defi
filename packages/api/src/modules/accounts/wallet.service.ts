import { Injectable } from '@nestjs/common';
import { SiweMessage } from 'siwe';

import { SupabaseService } from '../../clients/supabase/supabase.service';

import { LinkWalletDto } from './link-wallet.dto';

@Injectable()
export class WalletService {
  constructor(private readonly supabase: SupabaseService) {}

  async link(dto: LinkWalletDto) {
    const { message, signature } = dto;

    const supabase = this.supabase.client();

    const { error: authError, data: auth } = await supabase.auth.getUser();
    if (authError) return { error: authError, data: null };

    const { error: verifyError, data } = await new SiweMessage(message).verify({ signature });
    if (verifyError) return { error: verifyError, data: null };

    return supabase.from('user_wallets').insert({
      user_id: auth.user?.id,
      address: data.address,
    });
  }
}
