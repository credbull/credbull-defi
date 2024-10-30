import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { useChainId, useChains } from "wagmi";
import { RedeemRequest } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

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
  const chains = useChains();
  const chianId = useChainId();

  const chain = chains?.filter(_chain => _chain?.id === chianId)[0];

  const [redeemRequests, setRedeemRequests] = useState<RedeemRequest[]>([]);

  useEffect(() => {
    async function getRequestIds() {
      if (!address || !deployedContractAddress || !deployedContractAbi || !chain) return;

      const provider = new ethers.JsonRpcProvider(chain?.rpcUrls?.default?.http[0]);
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

          totalShareAmount += ethers.toBigInt(share);

          // only yield if the deposit was in the past
          if (currentPeriod > depositPeriod) {
            try {
              const assetAmount = await contract.convertToAssetsForDepositPeriod(share, depositPeriod);
              totalAssetAmount += ethers.toBigInt(assetAmount);
            } catch (error) {
              notification.warning(
                "It seems like you are testing a wrong scenario! You may set the reduced rate and get back to a period where it is not effective anymore. So you will see a wrong number regarding the `Assets Amount` in some of your redeem requests.",
              );
            }
          } else {
            totalAssetAmount += ethers.toBigInt(share); // yield is 0, assets = shares
          }
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
