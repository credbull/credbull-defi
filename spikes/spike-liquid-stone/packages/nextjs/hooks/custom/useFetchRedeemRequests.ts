import { useEffect, useState } from "react";
import { Contract, ethers } from "ethers";
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
  const chainId = useChainId();

  const chain = chains?.filter(_chain => _chain?.id === chainId)[0];

  const [redeemRequests, setRedeemRequests] = useState<RedeemRequest[]>([]);
  const [redeemRequestsFetched, setRedeemRequestsFetched] = useState<boolean>(!!address);

  useEffect(() => {
    setRedeemRequestsFetched(false);

    async function getRedeemPeriod(contract: Contract) {
      try {
        return contract.minUnlockPeriod();
      } catch (error) {
        console.error(`Unable to fetch minimum lock period, defaulting to currentPeriod + 1`, error);
        return Promise.resolve(currentPeriod + 1);
      }
    }

    async function getRequestIds() {
      if (!address || !deployedContractAddress || !deployedContractAbi || !chain) {
        setRedeemRequestsFetched(true);
        return;
      }

      const provider = new ethers.JsonRpcProvider(chain?.rpcUrls?.default?.http[0]);
      const contract: Contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);
      const requests: RedeemRequest[] = [];
      const redeemPeriod = await getRedeemPeriod(contract);

      for (let i = 0; i <= redeemPeriod; i++) {
        try {
          await createRedeemRequest(i);
        } catch (error) {
          console.error(`Failed to fetch unlock request for period ${i}:`, error);
        }
      }

      async function createRedeemRequest(i: number) {
        const [depositPeriods, shares] = await contract.unlockRequests(address, i);

        if (shares.length === 0) return;

        let totalShareAmount = BigInt(0);
        let totalAssetAmount = BigInt(0);

        for (let index = 0; index < depositPeriods.length; index++) {
          const depositPeriod = depositPeriods[index];
          const share = shares[index];

          totalShareAmount += ethers.toBigInt(share);

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
            totalAssetAmount += ethers.toBigInt(share);
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
      setRedeemRequestsFetched(true);
    }

    getRequestIds();
  }, [address, deployedContractAddress, deployedContractAbi, currentPeriod, chain, refetch]);

  return { redeemRequests, redeemRequestsFetched };
};
