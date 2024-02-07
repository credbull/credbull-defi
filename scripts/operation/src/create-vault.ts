import { addYears, startOfWeek, startOfYear, subDays } from 'date-fns';

import { generateAddress, headers, login, supabase, userByEmail } from './utils/helpers';

const createParams = (params: {
  kycProvider?: string;
  asset?: string;
  matured?: boolean;
  upside?: string;
  tenant?: string;
}) => {
  const owner = process.env.PUBLIC_OWNER_ADDRESS;
  const operator = process.env.PUBLIC_OPERATOR_ADDRESS;

  const custodian = params.matured ? process.env.ADDRESSES_CUSTODIAN : generateAddress();
  const treasury = process.env.ADDRESSES_TREASURY;
  const activityReward = process.env.ADDRESSES_ACTIVITY_REWARD;

  const asset = params.asset;
  const kycProvider = params.kycProvider;

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

    const kycProvider = addresses.data.find((i) => i.contract_name === 'MockKYCProvider')?.address;
    const asset = addresses.data.find((i) => i.contract_name === 'MockStablecoin')?.address;
    const createVault = await fetch(
      `${process.env.API_BASE_URL}/vaults/create-vault${scenarios.upside ? '-upside' : ''}`,
      {
        method: 'POST',
        body: JSON.stringify(
          createParams({
            kycProvider,
            asset,
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
