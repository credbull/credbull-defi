import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { useChainId, useChains } from "wagmi";
import { UnlockRequest } from "~~/types/async";
import { MAX_PERIODS } from "~~/utils/async/config";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

export const useFetchUnlockRequests = ({
  address,
  deployedContractAddress,
  deployedContractAbi,
  currentPeriod,
  noticePeriod,
  refetch,
}: {
  address: string;
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  currentPeriod: number;
  noticePeriod: number;
  refetch: any;
}) => {
  const chains = useChains();
  const chianId = useChainId();

  const chain = chains?.filter(_chain => _chain?.id === chianId)[0];

  const [unlockRequests, setUnlockRequests] = useState<UnlockRequest[]>([]);

  useEffect(() => {
    async function getUnlockRequests() {
      try {
        if (!address || !deployedContractAddress || deployedContractAbi || !noticePeriod) return;

        const provider = new ethers.JsonRpcProvider(chain?.rpcUrls?.default?.http[0]);
        const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);
        const requests: UnlockRequest[] = [];

        for (let i = 0; i <= MAX_PERIODS + noticePeriod; i++) {
          const unlock = await contract.unlockRequestAmount(address, BigInt(i));

          const unlockAmount = BigInt(unlock || 0);

          if (unlockAmount > 0) {
            const unlockRequest: UnlockRequest = { requestId: i, unlockAmount: unlockAmount };
            requests.push(unlockRequest);
          }
        }
        setUnlockRequests(requests);
      } catch (error) {
        console.error("Error getting unlock requests:", error);
      }
    }

    getUnlockRequests();
  }, [address, deployedContractAddress, deployedContractAbi, currentPeriod, noticePeriod, refetch]);

  return { unlockRequests };
};
