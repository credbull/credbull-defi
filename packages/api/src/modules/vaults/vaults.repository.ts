import { NotFoundException } from '@nestjs/common';
import { SupabaseClient } from '@supabase/supabase-js';
import * as _ from 'lodash';

import { ServiceResponse } from '../../types/responses';
import { Database, Tables } from '../../types/supabase';

import { EntitiesDto } from './vaults.dto';

async function getContractAddress(
  chainId: string,
  name: string,
  supabase: SupabaseClient<Database>,
): Promise<ServiceResponse<Tables<'contracts_addresses'> | null | undefined>> {
  return supabase.from('contracts_addresses').select().eq('contract_name', name).eq('chain_id', chainId).single();
}

export async function getFactoryContractAddress(
  chainId: string,
  supabase: SupabaseClient<Database>,
): Promise<ServiceResponse<Tables<'contracts_addresses'> | null | undefined>> {
  return getContractAddress(chainId, 'CredbullFixedYieldVaultFactory', supabase);
}

export async function getFactoryUpsideContractAddress(
  chainId: string,
  supabase: SupabaseClient<Database>,
): Promise<ServiceResponse<Tables<'contracts_addresses'> | null | undefined>> {
  return getContractAddress(chainId, 'CredbullUpsideVaultFactory', supabase);
}

export async function addEntitiesAndDistribution(
  entities: EntitiesDto[],
  vault: Pick<Tables<'vaults'>, 'id' | 'address' | 'tenant'>,
  supabase: SupabaseClient<Database>,
): Promise<ServiceResponse<string>> {
  const entitiesMappedData = entities.map((en) => ({
    type: en.type,
    address: en.address === 'self' ? vault.address : en.address,
    vault_id: vault.id,
    tenant: vault.tenant,
  }));
  const entitiesData = await supabase.from('vault_entities').insert(entitiesMappedData).select();
  if (entitiesData.error) return entitiesData;
  if (!entitiesData.data) return { error: new NotFoundException() };

  if (entitiesData.data.length > 0) {
    const filteredEntities = entities.filter((i) => Boolean(i.percentage)) as Required<EntitiesDto>[];
    if (filteredEntities.length === 0) return { data: 'Vault created successfully' };

    const distributionData = filteredEntities.map(({ type, percentage }, order) => ({ order, type, percentage }));
    const distributionMappedData = distributionData.map((en) => {
      const entity = entitiesData.data.find((i) => i.type === en.type)!;
      return {
        entity_id: entity.id,
        tenant: entity.tenant,
        percentage: en.percentage,
        order: en.order,
      };
    });
    const configData = await supabase.from('vault_distribution_configs').insert(distributionMappedData).select();
    if (configData.error) return configData;
  }
  return { data: 'Vault created successfully' };
}

export async function getUnpausedVaults(vaults: ServiceResponse<Tables<'vaults'>[]>) {
  return _.compact(
    await Promise.all(
      (vaults.data || []).map(async (vault) => {
        const vaultContract = await this.contract(vault);
        const paused = await vaultContract.paused();
        return paused ? null : vault;
      }),
    ),
  );
}
