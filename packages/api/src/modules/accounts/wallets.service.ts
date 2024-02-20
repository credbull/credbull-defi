import { Injectable } from '@nestjs/common';
import { SiweMessage } from 'siwe';

import { SupabaseService } from '../../clients/supabase/supabase.service';
import { PartnerType } from '../../types/db.dto';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { DiscriminatorProvided, NoDiscriminator } from '../../utils/errors';

import { WalletDto } from './wallets.dto';

@Injectable()
export class WalletsService {
  constructor(private readonly supabase: SupabaseService) {}

  async link(dto: WalletDto): Promise<ServiceResponse<Tables<'user_wallets'>[]>> {
    const { message, signature } = dto;
    const client = this.supabase.client();

    const auth = await client.auth.getUser();
    if (auth.error) return { error: auth.error };

    if ((auth.data.user.app_metadata.partner_type as PartnerType) === 'channel' && !dto.discriminator) {
      return { error: NoDiscriminator };
    }

    if ((auth.data.user.app_metadata.partner_type as PartnerType) !== 'channel' && dto.discriminator) {
      return { error: DiscriminatorProvided };
    }

    const verify = await new SiweMessage(message).verify({ signature });
    if (verify.error) return { error: verify.error };

    const existing = await client.from('user_wallets').select().eq('address', verify.data.address).maybeSingle();
    if (existing.error) return { error: existing.error };
    if (existing.data) return { data: [existing.data] };

    return client
      .from('user_wallets')
      .insert({
        user_id: auth.data.user?.id,
        address: verify.data.address,
        discriminator: dto.discriminator,
      })
      .select();
  }
}
