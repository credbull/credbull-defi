import { CredbullVaultFactory, CredbullVaultFactory__factory } from '@credbull/contracts';
//TODO: Figure out a proper way to import deployment data
import * as deploymentData from '@credbull/contracts/deployments/31337.json';
import { ICredbull } from '@credbull/contracts/types/CredbullVault';
import { Injectable, OnModuleInit, Scope } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SupabaseClient } from '@supabase/supabase-js';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { Database } from '../../types/supabase';
import { Tables } from '../../types/supabase';

@Injectable({ scope: Scope.DEFAULT })
export class ListenerService implements OnModuleInit {
  private supabaseAdmin: SupabaseClient<Database>;

  constructor(
    private readonly ethers: EthersService,
    private readonly config: ConfigService,
  ) {}

  onModuleInit() {
    this.supabaseAdmin = this.getSupabaseAdmin();
  }

  /**
   * @notice - This method called on onModuleInit of Listener module.
   *           The service should be in default scope.
   */
  async listenToContractEvent() {
    const FactoryContractAddress = deploymentData.CredbullVaultFactory[0].address;
    const contract = this.getFactoryContract(FactoryContractAddress);
    const eventName = 'VaultDeployed';

    contract.on(eventName, async (vault: string, params: ICredbull.VaultParamsStruct) => {
      console.log(`Event ${eventName} detected: ${vault}`);

      await this.processEventData(vault, params);
    });

    console.log('Listening for Vault deploy events...');
  }

  private getFactoryContract(addr: string): CredbullVaultFactory {
    return CredbullVaultFactory__factory.connect(addr, this.ethers.socketDeployer());
  }

  private getSupabaseAdmin() {
    return SupabaseService.createAdmin(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private async processEventData(vault: string, params: ICredbull.VaultParamsStruct) {
    try {
      if (!this.supabaseAdmin) this.supabaseAdmin = this.getSupabaseAdmin();

      //Push vault
      const newVault = await this.updateVaultData(vault, params);

      if (newVault.error || !newVault.data) {
        console.log(newVault.error);
        throw newVault.error;
      }

      //Push entities
      const vaultId = newVault.data[0].id;
      const entities = await this.updateEntitiesData(vaultId, vault, params);

      if (entities.error || !entities.data) {
        console.log(entities.error);
        throw entities.error;
      }

      //Push config
      const configs = await this.updateConfigData(entities.data);

      if (configs.error || !configs.data) {
        throw configs.error;
      }
    } catch (e) {
      console.log(e);
    }
  }

  private async updateVaultData(vault: string, params: ICredbull.VaultParamsStruct) {
    return await this.supabaseAdmin
      .from('vaults')
      .insert([
        {
          type: 'fixed_yield',
          status: 'ready',
          opened_at: new Date(Number(params.openAt) * 1000).toISOString(),
          closed_at: new Date(Number(params.closesAt) * 1000).toISOString(),
          address: vault,
          strategy_address: vault,
          asset_address: params.asset,
        },
      ])
      .select();
  }

  private async updateEntitiesData(vaultId: number, vaultAddress: string, params: ICredbull.VaultParamsStruct) {
    return await this.supabaseAdmin
      .from('vault_distribution_entities')
      .insert([
        { vault_id: vaultId, address: params.custodian, type: 'custodian' },
        { vault_id: vaultId, address: params.kycProvider, type: 'kyc_provider' },
        { vault_id: vaultId, address: params.treasury, type: 'treasury' },
        { vault_id: vaultId, address: params.activityReward, type: 'activity_reward' },
        { vault_id: vaultId, address: vaultAddress, type: 'vault' },
      ])
      .select();
  }

  private async updateConfigData(entities: Tables<'vault_distribution_entities'>[]) {
    //Prepare config data
    const makeConfig = (e: any) => {
      if (['custodian', 'kyc_provider'].includes(e.type)) return [];

      const vault = { order: 0, percentage: 0.2 };
      const treasury = { order: 1, percentage: 0.8 };
      const activity_reward = { order: 2, percentage: 1 };

      const config = e.type === 'vault' ? vault : e.type === 'treasury' ? treasury : activity_reward;

      return [{ entity_id: e.id, ...config }];
    };

    return await this.supabaseAdmin.from('vault_distribution_configs').insert(entities.flatMap(makeConfig)).select();
  }
}
