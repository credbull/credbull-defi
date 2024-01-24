import { CredbullVaultFactory, CredbullVaultFactory__factory } from '@credbull/contracts';
import * as DeploymentData from '@credbull/contracts/deployments/index.json';
import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';

@Injectable()
export class SyncEventService implements OnModuleInit {
  onModuleInit() {
    console.log('Sync Event init');
    this.sync();
  }

  constructor(
    private readonly ethers: EthersService,
    private readonly config: ConfigService,
  ) {}

  @Cron(CronExpression.EVERY_3_HOURS)
  syncEventData() {
    console.log('syncing data....');
  }

  private async sync() {
    const chainId = await this.ethers.networkId();
    const factoryContract = this.getFactoryContract(
      DeploymentData[`${chainId}` as '31337'].CredbullVaultFactory[0].address,
    );

    const eventFilter = factoryContract.filters.VaultDeployed();

    const events = await factoryContract.queryFilter(eventFilter);

    console.log(events);
  }

  private getSupabaseAdmin() {
    return SupabaseService.createAdmin(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private getFactoryContract(addr: string): CredbullVaultFactory {
    return CredbullVaultFactory__factory.connect(addr, this.ethers.socketDeployer());
  }
}
