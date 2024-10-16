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
        const unlockAmount = await contract.unlockRequestAmount(address, i);

        if (unlockAmount > 0) {
          const redeemRequest: RedeemRequest = {
            id: i,
            amount: ethers.formatUnits(unlockAmount, 6) as unknown as bigint,
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
