import { CredbullFixedYieldVaultWithUpside, CredbullFixedYieldVaultWithUpside__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SupabaseClient } from '@supabase/supabase-js';
import { BigNumberish } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Database } from '../../types/supabase';
import { responseFromWrite } from '../../utils/contracts';

@Injectable()
export class UpdateUpsideTwapService {
  private supabaseAdmin: SupabaseClient<Database>;

  constructor(
    private readonly ethers: EthersService,
    private readonly config: ConfigService,
  ) {}

  @Cron(CronExpression.EVERY_6_HOURS)
  async updateTWAP() {
    console.log('Updating twap data...');
    this.supabaseAdmin = this.admin();

    const vaults = await this.vaults();
    if (vaults.error || !vaults.data) {
      console.log(vaults.error || 'No vaults found');
      return;
    }

    const twap = await this.twap();
    if (twap.error) {
      console.log(twap.error);
      return;
    }

    for (const { address } of vaults.data) {
      const vault = await this.contract(address);
      const updated = await responseFromWrite(vault.setTWAP(twap.data));
      if (updated.error) console.log(updated.error);
    }

    console.log(`Updated all vaults with TWAP: ${twap.data}`);
  }

  private async vaults() {
    return this.supabaseAdmin.from('vaults').select().eq('type', 'fixed_yield_upside').eq('status', 'ready');
  }

  private async twap(): Promise<ServiceResponse<BigNumberish>> {
    // TODO: replace this whenever we have a real exchange to retrieve the TWAP from
    return Promise.resolve({ data: 1 });
  }

  private admin() {
    return SupabaseService.createAdmin(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private async contract(addr: string): Promise<CredbullFixedYieldVaultWithUpside> {
    return CredbullFixedYieldVaultWithUpside__factory.connect(addr, await this.ethers.deployer());
  }
}
