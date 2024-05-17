import { CredbullFixedYieldVaultWithUpside, CredbullFixedYieldVaultWithUpside__factory } from '@credbull/contracts';
import { ConsoleLogger, Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SupabaseClient } from '@supabase/supabase-js';
import { BigNumberish } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { ServiceResponse } from '../../types/responses';
import { Database } from '../../types/supabase';
import { responseFromWrite } from '../../utils/contracts';

@Injectable()
export class UpdateUpsideTwapService {
  private supabaseAdmin: SupabaseClient<Database>;

  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseAdminService,
    private readonly logger: ConsoleLogger,
  ) {
    this.logger.setContext(this.constructor.name);
  }

  @Cron(CronExpression.EVERY_6_HOURS)
  async updateTWAP() {
    this.logger.log('Updating twap data...');
    this.supabaseAdmin = this.supabase.admin();

    const vaults = await this.vaults();
    if (vaults.error || !vaults.data) {
      this.logger.error(vaults.error || 'No vaults found');
      return;
    }

    const twap = await this.twap();
    if (twap.error) {
      this.logger.error(twap.error);
      return;
    }

    for (const { address } of vaults.data) {
      const vault = await this.contract(address);
      const updated = await responseFromWrite(vault, vault.setTWAP(twap.data));
      if (updated.error) this.logger.error(updated.error);
    }

    this.logger.log(`Updated all vaults with TWAP: ${twap.data}`);
  }

  private async vaults() {
    return this.supabaseAdmin
      .from('vaults')
      .select()
      .eq('type', 'fixed_yield_upside')
      .eq('status', 'ready')
      .lte('deposits_opened_at', 'now()')
      .gte('deposits_closed_at', 'now()');
  }

  private async twap(): Promise<ServiceResponse<BigNumberish>> {
    // TODO: replace this whenever we have a real exchange to retrieve the TWAP from
    return Promise.resolve({ data: 100_00 });
  }

  private async contract(addr: string): Promise<CredbullFixedYieldVaultWithUpside> {
    return CredbullFixedYieldVaultWithUpside__factory.connect(addr, await this.ethers.operator());
  }
}
