import { CredbullVaultFactory__factory } from '@credbull/contracts';
import { addYears, startOfWeek, startOfYear, subDays } from 'date-fns';

import { generateAddress, headers, login, signer, supabase, userByEmail } from './utils/helpers';

const createParams = (params: {
  custodian: string;
  kycProvider?: string;
  asset?: string;
  token?: string;
  matured?: boolean;
  upside?: string;
  tenant?: string;
}) => {
  const owner = process.env.PUBLIC_OWNER_ADDRESS;
  const operator = process.env.PUBLIC_OPERATOR_ADDRESS;

  const treasury = process.env.ADDRESSES_TREASURY;
  const activityReward = process.env.ADDRESSES_ACTIVITY_REWARD;

  const asset = params.asset;
  const token = params.token;
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

  return {
    shareName: 'Credbull Liquidity',
    shareSymbol: 'CLTP',
    promisedYield: 10,
    depositOpensAt: depositDateAsTimestamp,
    depositClosesAt: depositDateAsTimestamp + week,
    redemptionOpensAt: redemptionDateAsTimestamp,
    redemptionClosesAt: redemptionDateAsTimestamp + week,
    owner,
    operator,
    asset,
    token,
    custodian,
    kycProvider,
    treasury,
    activityReward,
    entities,
    tenant: params.tenant,
  };
};

export const main = (
  scenarios: { matured: boolean; upside: boolean; tenant: boolean },
  params?: { upsideVault: string; tenantEmail: string },
) => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    const supabaseClient = supabase({ admin: true });

    const addresses = await supabaseClient.from('contracts_addresses').select();
    if (addresses.error) return addresses;

    const admin = await login({ admin: true });
    const adminHeaders = headers(admin);
    const adminSigner = signer(process.env.ADMIN_PRIVATE_KEY);

    // allow custodian address
    const custodian = scenarios.matured ? process.env.ADDRESSES_CUSTODIAN! : generateAddress();
    const factoryAddress = addresses.data.find(
      (i) => i.contract_name === (scenarios.upside ? 'CredbullVaultWithUpsideFactory' : 'CredbullVaultFactory'),
    )?.address;

    const factory = CredbullVaultFactory__factory.connect(factoryAddress!, adminSigner);
    const allowTx = await factory.allowCustodian(custodian);
    await allowTx.wait();

    const kycProvider = addresses.data.find((i) => i.contract_name === 'MockKYCProvider')?.address;
    const asset = addresses.data.find((i) => i.contract_name === 'MockStablecoin')?.address;
    const token = addresses.data.find((i) => i.contract_name === 'MockToken')?.address;
    const createVault = await fetch(
      `${process.env.API_BASE_URL}/vaults/create-vault${scenarios.upside ? '-upside' : ''}`,
      {
        method: 'POST',
        body: JSON.stringify(
          createParams({
            custodian,
            kycProvider,
            asset,
            token,
            matured: scenarios.matured,
            upside: scenarios.upside ? params?.upsideVault : undefined,
            tenant: scenarios.tenant && params?.tenantEmail ? (await userByEmail(params?.tenantEmail)).id : undefined,
          }),
        ),
        ...adminHeaders,
      },
    );

    const vaults = await createVault.json();
    console.log('Vaults: ', vaults);

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
