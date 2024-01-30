import { CredbullVaultFactory, CredbullVaultFactory__factory } from '@credbull/contracts';
import * as DeploymentData from '@credbull/contracts/deployments/index.json';
import { VaultDeployedEvent } from '@credbull/contracts/types/CredbullVaultFactory';
import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SupabaseClient } from '@supabase/supabase-js';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { Database, Tables } from '../../types/supabase';
import { ErrorHandlerService } from '../errors/errors.service';

@Injectable()
export class SyncEventService implements OnModuleInit {
  private supabaseAdmin: SupabaseClient<Database>;

  onModuleInit() {
    this.supabaseAdmin = this.getSupabaseAdmin();
  }

  constructor(
    private readonly ethers: EthersService,
    private readonly errorHandler: ErrorHandlerService,
    private readonly config: ConfigService,
  ) {}

  @Cron(CronExpression.EVERY_30_MINUTES)
  async syncEventData() {
    console.log('Syncing vault data...');
    await this.sync();
  }

  private async sync() {
    try {
      const { data, error } = await this.supabaseAdmin.from('vaults').select();

      if (error) {
        console.log(error);
        throw error;
      }

      const chainId = await this.ethers.networkId();
      const factoryContract = this.getFactoryContract(
        DeploymentData[`${chainId}` as '31337'].CredbullVaultFactory[0].address,
      );
      const eventFilter = factoryContract.filters.VaultDeployed();
      const events = await factoryContract.queryFilter(eventFilter);

      if (data.length === 0) {
        //Add all past events if any
        if (events.length > 0) {
          await this.processEventData(events);
        }
        return;
      }

      if (data.length > 0) {
        //add missing data
        const vaultsInDB = data.map((vault) => vault.address);
        const vaultsToBeAdded = events.filter((event) => {
          if (!vaultsInDB.includes(event.args.vault)) {
            return event;
          }
        });

        await this.processEventData(vaultsToBeAdded);
        return;
      }

      if (data.length > events.length) {
        const vaults = data.map((vault) => vault.address);
        //Remove duplicates
        vaults.filter(async (vault, index) => {
          if (vaults.indexOf(vault) != index) {
            await this.supabaseAdmin.from('vaults').delete().eq('id', data[index].id);
          }
        });
        return;
      }
    } catch (e) {
      this.errorHandler.handleError(e);
    }
  }

  private getSupabaseAdmin() {
    return SupabaseService.createAdmin(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private getFactoryContract(addr: string): CredbullVaultFactory {
    return CredbullVaultFactory__factory.connect(addr, this.ethers.deployer());
  }

  private prepareVaultDataFromEvent(event: VaultDeployedEvent) {
    return {
      type: 'fixed_yield' as const,
      status: 'ready' as const,
      opened_at: new Date(Number(event.args.params.depositOpensAt) * 1000).toISOString(),
      closed_at: new Date(Number(event.args.params.depositClosesAt) * 1000).toISOString(),
      address: event.args.vault,
      strategy_address: event.args.vault,
      asset_address: event.args.params.asset,
    };
  }

  private prepareEntitiesDataFromEvent(events: VaultDeployedEvent[], vaults: Tables<'vaults'>[]) {
    return events.flatMap((event, index) => {
      return [
        { vault_id: vaults[index].id, address: event.args.params.custodian, type: 'custodian' as const },
        { vault_id: vaults[index].id, address: event.args.params.kycProvider, type: 'kyc_provider' as const },
        { vault_id: vaults[index].id, address: event.args.params.treasury, type: 'treasury' as const },
        {
          vault_id: vaults[index].id,
          address: event.args.params.activityReward,
          type: 'activity_reward' as const,
        },
        { vault_id: vaults[index].id, address: event.args.vault, type: 'vault' as const },
      ];
    });
  }

  private prepareConfigDataFromEntities(entities: Tables<'vault_distribution_entities'>) {
    if (['custodian', 'kyc_provider'].includes(entities.type)) return [];

    const vault = { order: 0, percentage: 0.2 };
    const treasury = { order: 1, percentage: 0.8 };
    const activity_reward = { order: 2, percentage: 1 };

    const config = entities.type === 'vault' ? vault : entities.type === 'treasury' ? treasury : activity_reward;

    return [{ entity_id: entities.id, ...config }];
  }

  private async processEventData(events: VaultDeployedEvent[]) {
    try {
      //Push vault
      const newVaults = await this.supabaseAdmin
        .from('vaults')
        .insert(events.map(this.prepareVaultDataFromEvent))
        .select();

      if (newVaults.error || !newVaults.data) {
        console.log(newVaults.error);
        throw newVaults.error;
      }

      //Push entities
      const entities = await this.supabaseAdmin
        .from('vault_distribution_entities')
        .insert(this.prepareEntitiesDataFromEvent(events, newVaults.data))
        .select();

      if (entities.error || !entities.data) {
        console.log(entities.error);
        throw entities.error;
      }

      //Push config
      const configs = await this.supabaseAdmin
        .from('vault_distribution_configs')
        .insert(entities.data.flatMap(this.prepareConfigDataFromEntities))
        .select();

      if (configs.error || !configs.data) {
        throw configs.error;
      }
    } catch (e) {
      this.errorHandler.handleError(e);
    }
  }
}
