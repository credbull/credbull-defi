import { CredbullVaultWithUpsideFactory, CredbullVaultWithUpsideFactory__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SupabaseClient } from '@supabase/supabase-js';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { Database } from '../../types/supabase';
import { responseFromRead } from '../../utils/contracts';

import { getFactoryUpsideContractAddress } from './vaults.repository';

@Injectable()
export class SyncStrategiesService {
  private supabaseAdmin: SupabaseClient<Database>;

  constructor(
    private readonly ethers: EthersService,
    private readonly config: ConfigService,
  ) {}

  @Cron(CronExpression.EVERY_MINUTE)
  async syncEventData() {
    console.log('Syncing strategies data...');
    await this.sync();
  }

  private async sync() {
    this.supabaseAdmin = this.getSupabaseAdmin();

    const vaults = await this.supabaseAdmin.from('vaults').select();
    if (vaults.error) {
      console.log(vaults.error);
      return;
    }

    const chainId = await this.ethers.networkId();
    const factoryAddress = await getFactoryUpsideContractAddress(chainId.toString(), this.supabaseAdmin);
    if (factoryAddress.error || !factoryAddress.data) {
      console.log(factoryAddress.error || 'No factory address');
      return;
    }

    const factoryContract = await this.factoryUpsideContract(factoryAddress.data.address);
    const eventFilter = factoryContract.filters.VaultStrategySet();
    const events = await responseFromRead(factoryContract.queryFilter(eventFilter));
    if (events.error) {
      console.log(events.error);
      return;
    }

    //Add all past events if any
    if (events.data.length > 0) {
      const errors = [];
      for (const event of events.data) {
        const update = await this.supabaseAdmin
          .from('vaults')
          .update({ strategy_address: event.args.strategy })
          .eq('address', event.args.vault)
          .neq('strategy_address', event.args.strategy);

        if (update.error) errors.push(update.error);
      }

      if (errors.length > 0) {
        console.log(new AggregateError(errors));
        return;
      }
    }
  }

  private getSupabaseAdmin() {
    return SupabaseService.createAdmin(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private async factoryUpsideContract(addr: string): Promise<CredbullVaultWithUpsideFactory> {
    return CredbullVaultWithUpsideFactory__factory.connect(addr, await this.ethers.deployer());
  }
}
