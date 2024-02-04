import { NotFoundException } from '@nestjs/common';
import { SupabaseClient } from '@supabase/supabase-js';

import { ServiceResponse } from '../../types/responses';
import { Database, Tables } from '../../types/supabase';

import { EntitiesDto } from './vaults.dto';

export async function getFactoryContractAddress(
  chainId: string,
  supabase: SupabaseClient<Database>,
): Promise<ServiceResponse<Tables<'contracts_addresses'> | null | undefined>> {
  return supabase
    .from('contracts_addresses')
    .select()
    .eq('contract_name', 'CredbullVaultFactory')
    .eq('chain_id', chainId)
    .single();
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

  const filteredEntities = entities.filter((i) => Boolean(i.percentage)) as Required<EntitiesDto>[];
  const distributionData = filteredEntities.map(({ type, percentage }, order) => ({ order, type, percentage }));

  if (entitiesData.data.length > 0) {
    const distributionMappedData = distributionData.map((en) => {
      const entity = entitiesData.data.filter((i) => i.type === en.type)[0];
      return { entity_id: entity.id, percentage: en.percentage, order: en.order, tenant: entity.tenant };
    });

    const configData = await supabase.from('vault_distribution_configs').insert(distributionMappedData).select();
    if (configData.error) return configData;
  }
  return { data: 'Vault created successfully' };
}
