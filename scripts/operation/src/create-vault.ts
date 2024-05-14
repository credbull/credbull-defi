import {
  CredbullFixedYieldVault__factory,
  CredbullFixedYieldVaultFactory__factory,
  CredbullVaultFactory__factory,
} from '@credbull/contracts';
import { addYears, startOfWeek, startOfYear, subDays } from 'date-fns';

import { headers, login, signer, supabase, userByEmail } from './utils/helpers';
import {ICredbull} from "@credbull/contracts/types/UpsideVault";
import VaultParamsStruct = ICredbull.VaultParamsStruct;

type CreateVaultParams = {
  // separate struct
  treasury: string | undefined;
  activityReward: string | undefined;

  collateralPercentage: number;

  entities: Array<{ type: string; address: string | undefined; percentage?: number }>;
  tenant?: string;
};

function createParams(params: {
  custodian: string;
  kycProvider?: string;
  asset?: string;
  token?: string;
  matured?: boolean;
  upside?: string;
  tenant?: string;
}): [VaultParamsStruct, CreateVaultParams] {
  const treasury = process.env.ADDRESSES_TREASURY;
  const activityReward = process.env.ADDRESSES_ACTIVITY_REWARD;

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
    {type: 'treasury', address: treasury, percentage: 0.8},
    {type: 'activity_reward', address: activityReward, percentage: 1},
    {type: 'custodian', address: custodian},
    {type: 'kyc_provider', address: kycProvider},
  ];

  const entities = params.upside
      ? [{type: 'vault', address: params.upside, percentage: 0.2}, ...baseEntities]
      : baseEntities;

  const vaultParams: VaultParamsStruct = {
    owner: process.env.PUBLIC_OWNER_ADDRESS!,
    operator: process.env.PUBLIC_OPERATOR_ADDRESS!,
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
    treasury: process.env.ADDRESSES_TREASURY,
    activityReward: process.env.ADDRESSES_ACTIVITY_REWARD,
    collateralPercentage: Number(process.env.COLLATERAL_PERCENTAGE || 20),
    entities,
    tenant: params.tenant,
  };

  console.log('Vault Params:', vaultParams);
  console.log('Vault Extra Params:', vaultExtraParams);

  return [vaultParams, vaultExtraParams];
}

export const main = (
  scenarios: { matured: boolean; upside: boolean; tenant: boolean },
  params?: { upsideVault: string; tenantEmail: string },
) => {
  // function decodeContractError(contract: ethers.Contract, errorData: string) {
  //   const contractInterface = contract.interface;
  //   const selecter = errorData.slice(0, 10);
  //   const errorFragment = contractInterface.getError(selecter);
  //   const res = contractInterface.decodeErrorResult(errorFragment, errorData);
  //   const errorInputs = errorFragment.inputs;

  //   let message;
  //   if (errorInputs.length > 0) {
  //       message = errorInputs
  //           .map((input: any, index: any) => {
  //               return `${input.name}: ${res[index].toString()}`;
  //           })
  //           .join(', ');
  //   }

  //   throw new Error(`${errorFragment.name} | ${message ? message : ''}`);
  // }

  // const contractInstance = new ethers.Contract("0x5FbDB2315678afecb367f032d93F642f64180aa3", abi, new ethers.providers.JsonRpcProvider("http://localhost:8545"));

  // alternative option to calling the create-vault API.  not fully compatible with our arch (missing tenant information, maybe others)
  async function createVaultUsingEthers(factoryAddress: string, operatorSignerKey: string, vaultParams: ICredbull.VaultParamsStruct) {
    const factoryAsVaultOper = CredbullFixedYieldVaultFactory__factory.connect(factoryAddress!, signer(operatorSignerKey));
    const createVaultTx = await factoryAsVaultOper.createVault(vaultParams, "{}");
    await createVaultTx.wait();
  }

// decodeContractError(contractInstance, "0xe2517d3f000000000000000000000000cabe80b332aa9d900f5e32df51cb0bc5b276c55697667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929") ;
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    const supabaseClient = supabase({ admin: true });

    const addresses = await supabaseClient.from('contracts_addresses').select();
    if (addresses.error) return addresses;

    // TODO: ISSUE we are logging in here as the Admin User - but later we POST to the createVault owned by the OPERATOR
    const admin = await login({ admin: true });
    const adminHeaders = headers(admin);

    // for allowCustodian we need the Admin user.  for createVault we need the Operator Key.
    // the only way this works is if you go into supabase and associate the admin user with the Operator wallet
    const adminSigner = signer(process.env.ADMIN_PRIVATE_KEY);

    // allow custodian address
    let custodian = scenarios.matured ? process.env.ADDRESSES_CUSTODIAN! : process.env.ADDRESSES_CUSTODIAN || '';

    if (params?.upsideVault && !scenarios.upside) {
      const vault = await supabaseClient.from('vaults').select().eq('address', params.upsideVault).single();

      const upsideCustodian = await supabaseClient
        .from('vault_entities')
        .select()
        .eq('vault_id', vault.data!.id)
        .eq('type', 'custodian')
        .single();

      custodian = upsideCustodian.data!.address;
    }
    const factoryAddress = addresses.data.find(
      (i) => i.contract_name === (scenarios.upside ? 'CredbullUpsideVaultFactory' : 'CredbullFixedYieldVaultFactory'),
    )?.address;

    // TODO: this is the problem - the vaultFactory Admin (owner) is needed here
    // but later we call to createVault we should be using the operator
    const vaultFactoryAsAdmin = CredbullVaultFactory__factory.connect(factoryAddress!, adminSigner);
    const allowTx = await vaultFactoryAsAdmin.allowCustodian(custodian);
    await allowTx.wait();

    console.log(`!! CredbullVaultFactory ${factoryAddress} allowCustodian: ${custodian}`);


    const kycProvider = addresses.data.find((i) => i.contract_name === 'CredbullKYCProvider')?.address;
    const asset = addresses.data.find((i) => i.contract_name === 'MockStablecoin')?.address;
    const token = addresses.data.find((i) => i.contract_name === 'MockToken')?.address;

    const [vaultParams, createVaultParams] = createParams({custodian, kycProvider, asset, token, matured: scenarios.matured, upside: params?.upsideVault,
      tenant: scenarios.tenant && params?.tenantEmail ? (await userByEmail(params?.tenantEmail)).id : undefined,
    });

    let body = JSON.stringify({...vaultParams, ...createVaultParams}, null, 2);


    console.log('\n%%%%%%%%%%%%%%%%%%%%% start vaults/create-vault %%%%%%%%%%%%%%%%%%%%%');
    console.log('Request Body:', body);
    console.log('Request Headers:', { ...adminHeaders });

    const createVault = await fetch(
      `${process.env.API_BASE_URL}/vaults/create-vault${scenarios.upside ? '-upside' : ''}`,
      {
        method: 'POST',
        body: body,
        ...adminHeaders,
      },
    );

    const vaults = await createVault.json();

    console.log('\n%%%%%%%%%%%%%%%%%%%%% end vaults/create-vault %%%%%%%%%%%%%%%%%%%%%');

    // alternative - use a direct call instead of posting to the API
    // const operatorKey = process.env.OPERATOR_PRIVATE_KEY; // this should be the Vault Operator
    // await createVaultUsingEthers(factoryAddress, operatorKey, vaultParams);


    if (scenarios.matured) {
      const vault = CredbullFixedYieldVault__factory.connect(vaults.data[0].address, adminSigner);
      const toggleTx = await vault.toggleWindowCheck(false);
      await toggleTx.wait();
    }

    console.log('Vaults: ', vaults);

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
