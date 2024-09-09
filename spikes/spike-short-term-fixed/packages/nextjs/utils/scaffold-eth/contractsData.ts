import scaffoldConfig from "~~/scaffold.config";
import { contracts } from "~~/utils/scaffold-eth/contract";

export function getAllContracts() {
  const transformedContracts: Record<string, any[]> = {};

  if (contracts) {
    Object.keys(contracts).forEach((networkId: string) => {
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      transformedContracts[networkId] = [contracts![Number(networkId)]];
    });
  }

  // transformedContracts?.[scaffoldConfig.targetNetworks[0].id].push(
  //   transformedContracts?.[scaffoldConfig.targetNetworks[0].id][0],
  // );

  const contractsData = transformedContracts?.[scaffoldConfig.targetNetworks[0].id];

  return contractsData ? contractsData : [];
}
