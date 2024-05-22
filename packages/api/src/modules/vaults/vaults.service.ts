import {
  CredbullFixedYieldVault,
  CredbullFixedYieldVaultFactory,
  CredbullFixedYieldVaultFactory__factory,
  CredbullFixedYieldVault__factory,
  CredbullUpsideVaultFactory,
  CredbullUpsideVaultFactory__factory,
} from '@credbull/contracts';
import { ICredbull } from '@credbull/contracts/types/CredbullFixedYieldVault';
import { Injectable, NotFoundException } from '@nestjs/common';
import { BigNumber, type ContractTransaction } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';

import { VaultParamsDto } from './vaults.dto';
import {
  addEntitiesAndDistribution,
  getFactoryContractAddress,
  getFactoryUpsideContractAddress,
  getUnpausedVaults,
} from './vaults.repository';

@Injectable()
export class VaultsService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
    private readonly supabaseAdmin: SupabaseAdminService,
  ) {}

  async current(): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    const vaults = await this.supabase
      .client()
      .from('vaults')
      .select('*')
      .neq('status', 'created')
      .lt('deposits_opened_at', 'now()');
    if (vaults.error || !vaults.data) return vaults;

    const unPausedVaults = await getUnpausedVaults(vaults, await this.ethers.operator());
    return { data: unPausedVaults, error: null };
  }

  async vaultEntities(vaultId: number): Promise<ServiceResponse<Tables<'vault_entities'>[]>> {
    const { data, error } = await this.supabase.client().from('vault_entities').select('*').eq('vault_id', vaultId);

    if (error) return { data, error };
    return { data: data, error: null };
  }

  async createVault(
    params: VaultParamsDto,
    upside?: boolean,
    collateralPercentage?: number,
  ): Promise<ServiceResponse<Tables<'vaults'>>> {
    const chainId = await this.ethers.networkId();
    const factoryAddress = upside
      ? await getFactoryUpsideContractAddress(chainId.toString(), this.supabaseAdmin.admin())
      : await getFactoryContractAddress(chainId.toString(), this.supabaseAdmin.admin());

    if (factoryAddress.error) return factoryAddress;
    if (!factoryAddress.data) return { error: new NotFoundException() };

    const factory = await this.factoryContract(factoryAddress.data.address);
    const upsideFactory = await this.factoryUpsideContract(factoryAddress.data.address);

    const options = JSON.stringify({ entities: params.entities, tenant: params.tenant });

    if (!collateralPercentage) collateralPercentage = 0;

    const fixedYieldVaultParams = this.createVaultParams(params);

    const readMethod: Promise<BigNumber> = upside
      ? upsideFactory.estimateGas.createVault(fixedYieldVaultParams, params.token, collateralPercentage, options)
      : factory.estimateGas.createVault(fixedYieldVaultParams, options);

    const estimation = await responseFromRead(upside ? upsideFactory : factory, readMethod);
    if (estimation.error) {
      return estimation;
    }

    const writeMethod: Promise<ContractTransaction> = upside
      ? upsideFactory.createVault(fixedYieldVaultParams, params.token, collateralPercentage, options, {
          gasLimit: estimation.data,
        })
      : factory.createVault(fixedYieldVaultParams, options, { gasLimit: estimation.data });

    const response = await responseFromWrite(upside ? upsideFactory : factory, writeMethod);
    if (response.error) return response;

    console.log(response);

    const vaultAddress = response.data.events?.find((e) => e.event === 'VaultDeployed')?.args?.[0];
    const createdVault = await this.createVaultInDB(params, vaultAddress, !!upside);
    if (createdVault.error) return createdVault;

    const entities = await addEntitiesAndDistribution(params.entities, createdVault.data, this.supabaseAdmin.admin());
    if (entities.error) return entities;

    return await this.readyVaultInDB(createdVault.data);
  }

  private createVaultParams(params: VaultParamsDto): ICredbull.FixedYieldVaultParamsStruct {
    const baseVaultParams = {
      asset: params.asset,
      shareName: params.shareName,
      shareSymbol: params.shareSymbol,
      custodian: params.custodian,
    };

    const contractRoles = {
      owner: params.owner,
      operator: params.operator,
      custodian: params.custodian,
    };

    const depositWindowParam = {
      opensAt: params.depositOpensAt,
      closesAt: params.depositClosesAt,
    };

    const matureWindowParam = {
      opensAt: params.redemptionOpensAt,
      closesAt: params.redemptionClosesAt,
    };

    const windowVaultParams = {
      depositWindow: depositWindowParam,
      matureWindow: matureWindowParam,
    };

    const kycParams = {
      kycProvider: params.kycProvider,
      depositThresholdForWhitelisting: params.depositThresholdForWhitelisting,
    };

    const maxCapParams = {
      maxCap: params.maxCap,
    };

    return {
      baseVaultParams,
      contractRoles,
      windowVaultParams,
      kycParams,
      maxCapParams,
      promisedYield: params.promisedYield,
    };
  }

  private async createVaultInDB(params: VaultParamsDto, vaultAddress: string, upside: boolean) {
    const vaultData = {
      type: upside ? 'fixed_yield_upside' : 'fixed_yield',
      status: 'created' as const,
      deposits_opened_at: new Date(Number(params.depositOpensAt) * 1000).toISOString(),
      deposits_closed_at: new Date(Number(params.depositClosesAt) * 1000).toISOString(),
      redemptions_opened_at: new Date(Number(params.redemptionOpensAt) * 1000).toISOString(),
      redemptions_closed_at: new Date(Number(params.redemptionClosesAt) * 1000).toISOString(),
      address: vaultAddress,
      strategy_address: vaultAddress,
      asset_address: params.asset,
      tenant: params.tenant,
    } as Tables<'vaults'>;

    return this.supabaseAdmin.admin().from('vaults').insert(vaultData).select().single();
  }

  private async readyVaultInDB(vault: Pick<Tables<'vaults'>, 'id'>) {
    return this.supabaseAdmin.admin().from('vaults').update({ status: 'ready' }).eq('id', vault.id).select().single();
  }

  private async factoryContract(addr: string): Promise<CredbullFixedYieldVaultFactory> {
    return CredbullFixedYieldVaultFactory__factory.connect(addr, await this.ethers.operator());
  }

  private async vaultContract(addr: string): Promise<CredbullFixedYieldVault> {
    return CredbullFixedYieldVault__factory.connect(addr, await this.ethers.operator());
  }

  private async factoryUpsideContract(addr: string): Promise<CredbullUpsideVaultFactory> {
    return CredbullUpsideVaultFactory__factory.connect(addr, await this.ethers.operator());
  }
}
