import { CredbullFixedYieldVault__factory, VaultFactory__factory } from '@credbull/contracts';
import { FixedYieldVault } from '@credbull/contracts/types/CredbullFixedYieldVault';
import { MaturityVault } from '@credbull/contracts/types/CredbullFixedYieldVault';
import { UpsideVault } from '@credbull/contracts/types/CredbullFixedYieldVaultWithUpside';
import { addYears, startOfWeek, startOfYear, subDays } from 'date-fns';

import { headers, login } from './utils/api';
import { assertEmailOptional, assertUpsideVault } from './utils/assert';
import { loadConfiguration } from './utils/config';
import { supabaseAdminClient } from './utils/database';
import { signerFor } from './utils/ethers';
import { Schema } from './utils/schema';
import { userByOrThrow } from './utils/user';

type CreateVaultParams = {
  treasury: string | undefined;
  activityReward: string | undefined;
  collateralPercentage: number;
  entities: Array<{ type: string; address: string | undefined; percentage?: number }>;
  tenant?: string;
};

function createParams(
  config: any,
  params: {
    custodian: string;
    whiteListProvider?: string;
    asset?: string;
    token?: string;
    matured?: boolean;
    upside?: string;
    tenant?: string;
  },
): [FixedYieldVault.FixedYieldVaultParamsStruct | UpsideVault.UpsideVaultParamsStruct, CreateVaultParams, any] {
  const treasury = config.evm.address.treasury;
  const activityReward = config.evm.address.activity_reward;
  const collateralPercentage = config.operation.createVault.collateral_percentage;

  const whiteListProvider = params.whiteListProvider;
  const custodian = params.custodian;

  const week = 604800;
  const currentYearStart = startOfYear(new Date());
  let depositOpensAt = startOfWeek(new Date());
  if (params.matured) depositOpensAt = startOfYear(subDays(currentYearStart, 1));

  const depositDateAsTimestamp = depositOpensAt.getTime() / 1000;

  const redemptionOpensAt = addYears(depositOpensAt, 1);
  const redemptionDateAsTimestamp = redemptionOpensAt.getTime() / 1000;

  const baseEntities = [
    { type: 'treasury', address: treasury, percentage: 0.8 },
    { type: 'activity_reward', address: activityReward, percentage: 1 },
    { type: 'custodian', address: custodian },
    { type: 'whitelist_provider', address: whiteListProvider },
  ];

  const entities = params.upside
    ? [{ type: 'vault', address: params.upside, percentage: 0.2 }, ...baseEntities]
    : baseEntities;

  const tempParams = {
    owner: config.evm.address.owner,
    operator: config.evm.address.operator,
    asset: params.asset || '',
    token: params.token || '',
    shareName: 'Credbull Liquidity',
    shareSymbol: 'CLTP',
    promisedYield: 10,
    depositOpensAt: depositDateAsTimestamp,
    depositClosesAt: depositDateAsTimestamp + week,
    redemptionOpensAt: redemptionDateAsTimestamp,
    redemptionClosesAt: redemptionDateAsTimestamp + week,
    custodian: params.custodian,
    whiteListProvider: params.whiteListProvider || '',
    maxCap: (1e6 * 1e6).toString(),
    depositThresholdForWhiteListing: (1000e6).toString(),
  };

  const maturityVaultParams: MaturityVault.MaturityVaultParamsStruct = {
    vault: {
      asset: tempParams.asset,
      shareName: tempParams.shareName,
      shareSymbol: tempParams.shareSymbol,
      custodian: tempParams.custodian,
    },
  };

  const fixedYieldVaultParams: FixedYieldVault.FixedYieldVaultParamsStruct = {
    maturityVault: maturityVaultParams,
    roles: {
      owner: tempParams.owner,
      operator: tempParams.operator,
      custodian: tempParams.custodian,
    },
    windowPlugin: {
      depositWindow: {
        opensAt: tempParams.depositOpensAt,
        closesAt: tempParams.depositClosesAt,
      },
      redemptionWindow: {
        opensAt: tempParams.redemptionOpensAt,
        closesAt: tempParams.redemptionClosesAt,
      },
    },
    whiteListPlugin: {
      whiteListProvider: tempParams.whiteListProvider,
      depositThresholdForWhiteListing: tempParams.depositThresholdForWhiteListing,
    },
    maxCapPlugin: {
      maxCap: tempParams.maxCap,
    },
    promisedYield: tempParams.promisedYield,
  };

  const upsideVaultParams: UpsideVault.UpsideVaultParamsStruct = {
    fixedYieldVault: fixedYieldVaultParams,
    cblToken: tempParams.token,
    collateralPercentage: collateralPercentage,
  };

  const vaultExtraParams: CreateVaultParams = {
    treasury: treasury,
    activityReward: activityReward,
    collateralPercentage: collateralPercentage,
    entities,
    tenant: params.tenant,
  };

  const vaultParams = params.upside ? upsideVaultParams : fixedYieldVaultParams;

  console.log('Vault Params:', fixedYieldVaultParams);
  console.log('Vault Extra Params:', vaultExtraParams);

  return [vaultParams, vaultExtraParams, tempParams];
}

// TODO (JL,2024-06-10): Understand Tenancy & Tenant Email.

/**
 * Creates a Vault according to the parameters.
 *
 * @param config The applicable configuration. Must be valid against a schema.
 * @param isMatured `true` if the Vault is to be created matured, or not.
 * @param isUpside `true` is an Fixed Yield With Upside Vault is to be created.
 * @param isTenant (JL,2024-06-18): Don't Know.
 * @param upsideVault The `string` Address of the Fixed Yield With Upside Vault.
 * @param tenantEmail (JL,2024-06-18): Don't Know.
 * @throws ZodError if any parameter or config item fails validation.
 * @throws PostgrestError if authentication or any database interaction fails.
 * @throws Error if there are no contracts to operate upon.
 */
export async function createVault(
  config: any,
  isMatured: boolean,
  isUpside: boolean,
  isTenant: boolean,
  upsideVault?: string,
  tenantEmail?: string,
): Promise<any> {
  Schema.CONFIG_API_URL.parse(config);
  Schema.CONFIG_ADMIN_PRIVATE_KEY.parse(config);
  Schema.CONFIG_EVM_ADDRESS.parse(config);
  Schema.CONFIG_OPERATION_CREATE_VAULT.parse(config);
  assertUpsideVault(upsideVault);
  assertEmailOptional(tenantEmail);

  const supabaseAdmin = supabaseAdminClient(config);
  const addresses = await supabaseAdmin.from('contracts_addresses').select();
  if (addresses.error) throw addresses.error;

  console.log('='.repeat(80));

  // for allowCustodian we need the Admin user.  for createVault we need the Operator Key.
  // the only way this works is if you go into supabase and associate the admin user with the Operator wallet
  const adminSigner = signerFor(config, config.secret.ADMIN_PRIVATE_KEY);

  // TODO: ISSUE we are logging in here as the Admin User - but later we POST to the createVault owned by the OPERATOR
  const admin = await login(config, config.users.admin.email_address, config.secret.ADMIN_PASSWORD);
  const adminHeaders = headers(admin);

  // Require Custodian address for a Matured Vault. Allow it otherwise.
  // NOTE (JL,2024-05-31): This may be spurious, as Custodian is always configured.
  let custodian = isMatured ? config.evm.address.custodian : config.evm.address.custodian || '';

  if (upsideVault && !isUpside) {
    const vault = await supabaseAdmin.from('vaults').select().eq('address', upsideVault).single();
    const upsideCustodian = await supabaseAdmin
      .from('vault_entities')
      .select()
      .eq('vault_id', vault.data!.id)
      .eq('type', 'custodian')
      .single();

    custodian = upsideCustodian.data!.address;
    console.log(' Queried Custodian Address for Vault:', upsideVault);
  }
  console.log(' Custodian Address:', custodian);

  const expectedFactoryName = isUpside ? 'CredbullUpsideVaultFactory' : 'CredbullFixedYieldVaultFactory';
  const factoryAddress = addresses.data.find((i) => i.contract_name === expectedFactoryName)?.address;
  console.log(` ${expectedFactoryName} Address: ${factoryAddress}`);

  // TODO: this is the problem - the vaultFactory Admin (owner) is needed here
  // but later we call to createVault we should be using the operator
  const vaultFactoryAsAdmin = VaultFactory__factory.connect(factoryAddress!, adminSigner);
  const allowTx = await vaultFactoryAsAdmin.allowCustodian(custodian);
  await allowTx.wait();
  console.log(` Allowed Custodian ${custodian} on ${expectedFactoryName} ${factoryAddress}`);

  const whiteListProvider = addresses.data.find((i: any) => i.contract_name === 'CredbullWhiteListProvider')?.address;
  const asset = addresses.data.find((i: any) => i.contract_name === 'SimpleUSDC')?.address;
  const token = addresses.data.find((i: any) => i.contract_name === 'SimpleToken')?.address;

  const [, createVaultParams, tempParams] = createParams(config, {
    custodian,
    whiteListProvider,
    asset,
    token,
    matured: isMatured,
    upside: upsideVault,
    tenant: isTenant && tenantEmail ? (await userByOrThrow(supabaseAdmin, tenantEmail)).id : undefined,
  });

  const serviceUrl = new URL(`/vaults/create-vault${isUpside ? '-upside' : ''}`, config.api.url);
  let requestBody = JSON.stringify({ ...tempParams, ...createVaultParams }, null, 2);

  console.log('-'.repeat(80));
  console.log(' Creating Vault with:');
  console.log('  URL:', serviceUrl.href);
  console.log('  Request Headers:', { ...adminHeaders });
  console.log('  Request Body:', requestBody);

  const response = await fetch(serviceUrl, { method: 'POST', body: requestBody, ...adminHeaders });
  const responseBody = await response.json();

  console.log('-'.repeat(80));
  console.log('  Response Body:', responseBody);
  console.log('-'.repeat(80));

  if (!response.ok) throw new Error(responseBody.message);
  const {
    data: [created, ...rest],
  } = responseBody;
  if (rest && rest.length > 0) {
    console.log('WARNING: Response contained unexpected:', rest);
  }

  if (isMatured) {
    const vault = CredbullFixedYieldVault__factory.connect(created.address, adminSigner);
    const toggleTx = await vault.toggleWindowCheck();
    await toggleTx.wait();
    console.log('  Toggled Window Check OFF for Vault: ', created.address);
  }

  console.log('='.repeat(80));
  return created;
}

/**
 * Invoked by the command line processor, creates a Vault according to the  `scenarios` and `params`.
 *
 * @param scenarios Provides flags to govern the Vault Creation process.
 * @param params Optional parameters object.
 * @throws ZodError if the configuration fails to load or satisfy any configuration requirement.
 */
export async function main(
  scenarios: { matured: boolean; upside: boolean; tenant: boolean },
  params?: { upsideVault: string; tenantEmail: string },
) {
  await createVault(
    loadConfiguration(),
    scenarios.matured,
    scenarios.upside,
    scenarios.tenant,
    params?.upsideVault,
    params?.tenantEmail,
  );
}
