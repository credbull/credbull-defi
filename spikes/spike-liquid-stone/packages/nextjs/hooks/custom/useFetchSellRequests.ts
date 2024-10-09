import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { SellRequest } from "~~/types/vault";

export const useFetchSellRequests = ({
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
  const [sellRequests, setSellRequests] = useState<SellRequest[]>([]);

  useEffect(() => {
    async function getRequestIds() {
      if (!deployedContractAddress || !deployedContractAbi) return;

      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
      const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);
      const requests: SellRequest[] = [];

      for (let i = 0; i <= currentPeriod; i++) {
        const unlockAmount = await contract.unlockRequestAmount(address, i);

        if (unlockAmount > 0) {
          const sellRequest: SellRequest = { id: i, amount: ethers.formatUnits(unlockAmount, 6) as unknown as bigint };
          requests.push(sellRequest);
        }
      }

      setSellRequests(requests);
    }

    getRequestIds();
  }, [currentPeriod, refetch]);

  return { sellRequests };
};
