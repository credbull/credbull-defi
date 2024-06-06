import { z } from 'zod';
import { addYears, startOfWeek, startOfYear, subDays } from 'date-fns';

import {
  CredbullFixedYieldVault__factory,
  CredbullFixedYieldVaultFactory__factory,
  CredbullVaultFactory__factory,
} from '@credbull/contracts';

import type { ICredbull } from '@credbull/contracts/types/CredbullFixedYieldVaultFactory';

import { loadConfiguration } from './utils/config';
import { headers, login, signer, supabase, userByOrThrow } from './utils/helpers';

// Zod Schema to validate all config points in this module.
const addressSchema = z.string().regex(/^(0x)?[0-9a-fA-F]{40,40}$/);
const configSchema = z.object({
  secret: z.object({
    ADMIN_PRIVATE_KEY: z.string()
  }),
  api: z.object({
    url: z.string().url()
  }),
  evm: z.object({
    address: z.object({
      owner: addressSchema,
      operator: addressSchema,
      custodian: addressSchema,
      treasury: addressSchema,
      activity_reward: addressSchema,
    })
  }),
  operation: z.object({
    createVault: z.object({
      collateral_percentage: z.number()
    })
  })
});
const emailSchema = z.string().email();
const upsideVaultSchema = z.intersection(addressSchema, z.string().regex(/self/));

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
    kycProvider?: string;
    asset?: string;
    token?: string;
    matured?: boolean;
    upside?: string;
    tenant?: string;
  }
): [ICredbull.VaultParamsStruct, CreateVaultParams] {
  const treasury = config.evm.address.treasury;
  const activityReward = config.evm.address.activity_reward;

  const kycProvider = params.kycProvider;
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
    { type: 'kyc_provider', address: kycProvider },
  ];

  const entities = params.upside
    ? [{ type: 'vault', address: params.upside, percentage: 0.2 }, ...baseEntities]
    : baseEntities;

  const vaultParams: ICredbull.VaultParamsStruct = {
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
    kycProvider: params.kycProvider || '',
    maxCap: (1e6 * 1e6).toString(),
    depositThresholdForWhitelisting: (1000e6).toString(),
  };

  const vaultExtraParams: CreateVaultParams = {
    treasury: treasury,
    activityReward: activityReward,
    collateralPercentage: config.operation.collateral_percentage,
    entities,
    tenant: params.tenant,
  };

  return [vaultParams, vaultExtraParams];
}

/**
 * Creates a Vault according to the parameters.
 * 
 * @param config The applicable configuration. Must be valid against a schema.
 * @param isMatured `true` if the Vault is to be created matured, or not.
 * @param isUpside `true` is an Fixed Yield With Upside Vault is to be created. 
 * @param isTenant 
 * @param upsideVault The `string` Address of the Fixed Yield With Upside Vault.
 * @param tenantEmail 
 * @throws ZodError if any parameter or config item fails validation.
 * @throws PostgrestError if authentication or any database interaction fails.
 * @throws Error if there are no contracts to operate upon.
 */
export const createVault = async (
  config: any,
  isMatured: boolean,
  isUpside: boolean,
  isTenant: boolean,
  upsideVault?: string,
  tenantEmail?: string
): Promise<any> => {
  configSchema.parse(config);
  upsideVaultSchema.optional().parse(upsideVault);
  emailSchema.optional().parse(tenantEmail);

  const supabaseAdmin = supabase(config, { admin: true });
  const addresses = await supabaseAdmin.from('contracts_addresses').select();
  if (addresses.error) throw addresses.error;

  console.log('='.repeat(80));

  // for allowCustodian we need the Admin user.  for createVault we need the Operator Key.
  // the only way this works is if you go into supabase and associate the admin user with the Operator wallet
  const adminSigner = signer(config, config.secret.ADMIN_PRIVATE_KEY);

  // TODO: ISSUE we are logging in here as the Admin User - but later we POST to the createVault owned by the OPERATOR
  const admin = await login(config, { admin: true });
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
    console.log(' Queried Custodian Address for Vault: ' + upsideVault);
  }
  console.log(' Custodian Address: ' + custodian);

  const expectedFactoryName = (isUpside ? 'CredbullUpsideVaultFactory' : 'CredbullFixedYieldVaultFactory');
  const factoryAddress = addresses.data.find((i) => i.contract_name === expectedFactoryName)?.address;
  console.log(` ${expectedFactoryName} Address: ${factoryAddress}`);

  // TODO: this is the problem - the vaultFactory Admin (owner) is needed here
  // but later we call to createVault we should be using the operator
  const vaultFactoryAsAdmin = CredbullVaultFactory__factory.connect(factoryAddress!, adminSigner);
  const allowTx = await vaultFactoryAsAdmin.allowCustodian(custodian);
  await allowTx.wait();
  console.log(` Allowed Custodian ${custodian} on ${expectedFactoryName} ${factoryAddress}`);

  const kycProvider = addresses.data.find((i) => i.contract_name === 'CredbullKYCProvider')?.address;
  const asset = addresses.data.find((i) => i.contract_name === 'MockStablecoin')?.address;
  const token = addresses.data.find((i) => i.contract_name === 'MockToken')?.address;

  const [vaultParams, createVaultParams] = createParams(config, {
    custodian,
    kycProvider,
    asset,
    token,
    matured: isMatured,
    upside: upsideVault,
    tenant: isTenant && tenantEmail ? (await userByOrThrow(supabaseAdmin, tenantEmail)).id : undefined,
  });

  const serviceUrl = new URL(`/vaults/create-vault${isUpside ? '-upside' : ''}`, config.api.url);
  let body = JSON.stringify({ ...vaultParams, ...createVaultParams }, null, 2);

  console.log('-'.repeat(80));
  console.log(' Creating Vault with:');
  console.log('  URL: ', serviceUrl.href);
  console.log('  Request Headers: ', { ...adminHeaders });
  console.log('  Request Body: ', body);

  const response = await fetch(serviceUrl, { method: 'POST', body: body, ...adminHeaders });
  const { data: [created] } = await response.json();

  console.log('-'.repeat(80));
  console.log('  Response: ', created);
  console.log('-'.repeat(80));

  // alternative - use a direct call instead of posting to the API
  // const operatorKey = process.env.OPERATOR_PRIVATE_KEY; // this should be the Vault Operator
  // await createVaultUsingEthers(config, factoryAddress, operatorKey, vaultParams);

  if (isMatured) {
    const vault = CredbullFixedYieldVault__factory.connect(created.address, adminSigner);
    const toggleTx = await vault.toggleWindowCheck(false);
    await toggleTx.wait();
    console.log('  Toggled Window Check OFF for Vault: ', created.address);
  }

  console.log('='.repeat(80));
  return created;
};

/**
 * Invoked by the command line processor, creates a Vault according to the  `scenarios` and `params`. 
 * 
 * @param scenarios Provides flags to govern the Vault Creation process.
 * @param params Optional parameters object.
 * @throws ZodError if the configuration fails to load or satisfy any configuration requirement.
 */
export const main = (
  scenarios: { matured: boolean; upside: boolean; tenant: boolean },
  params?: { upsideVault: string; tenantEmail: string },
) => {
  setTimeout(async () => {
    createVault(
      loadConfiguration(),
      scenarios.matured,
      scenarios.upside,
      scenarios.tenant,
      params?.upsideVault,
      params?.tenantEmail
    )
  }, 1000);
};

// alternative option to calling the create-vault API.  not fully compatible with our arch (missing tenant 
// information, maybe others)
async function createVaultUsingEthers(
  config: any,
  factoryAddress: string,
  operatorSignerKey: string,
  vaultParams: ICredbull.VaultParamsStruct
) {
  const alternateSigner = signer(config, operatorSignerKey);
  const factoryAsVaultOper = CredbullFixedYieldVaultFactory__factory.connect(factoryAddress!, alternateSigner);
  const createVaultTx = await factoryAsVaultOper.createVault(vaultParams, "{}");
  await createVaultTx.wait();
}