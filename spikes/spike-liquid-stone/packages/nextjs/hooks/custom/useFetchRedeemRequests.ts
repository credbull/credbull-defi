import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { RedeemRequest } from "~~/types/vault";

export const useFetchRedeemRequests = ({
  address,
  deployedContractAddress,
  deployedContractAbi,
  currentPeriod,
  refetch,
}: {
  address: string;
  deployedContractAddress: string;
  deployedContractAbi: any;
  currentPeriod: number;
  refetch: any;
}) => {
  const [redeemRequests, setRedeemRequests] = useState<RedeemRequest[]>([]);

  useEffect(() => {
    async function getRequestIds() {
      if (!address || !deployedContractAddress || !deployedContractAbi) return;

      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
      const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);
      const requests: RedeemRequest[] = [];

      for (let i = 0; i <= currentPeriod + 1; i++) {
        // Fetch the deposit periods and amounts (shares) from unlockRequests
        const [depositPeriods, shares] = await contract.unlockRequests(address, i);

        // If there are no shares, skip this request
        if (shares.length === 0) continue;

        let totalShareAmount = BigInt(0);
        let totalAssetAmount = BigInt(0);

        // Loop through each deposit period and calculate the corresponding asset value
        for (let index = 0; index < depositPeriods.length; index++) {
          const depositPeriod = depositPeriods[index];
          const share = shares[index];

          // Call the contract function to convert shares to assets for each deposit period
          const assetAmount = await contract.convertToAssetsForDepositPeriod(share, depositPeriod);

          totalShareAmount += ethers.toBigInt(share);
          totalAssetAmount += ethers.toBigInt(assetAmount);
        }

        if (totalShareAmount > 0) {
          const redeemRequest: RedeemRequest = {
            id: i,
            shareAmount: ethers.formatUnits(totalShareAmount, 6) as unknown as bigint,
            assetAmount: ethers.formatUnits(totalAssetAmount, 6) as unknown as bigint,
          };
          requests.push(redeemRequest);
        }
      }

      setRedeemRequests(requests);
    }

    getRequestIds();
  }, [address, deployedContractAddress, deployedContractAbi, currentPeriod, refetch]);

  return { redeemRequests };
};
