import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { useChainId, useChains } from "wagmi";
import { RequestDetail } from "~~/types/async";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

export const useFetchRequestDetails = ({
  address,
  deployedContractAddress,
  deployedContractAbi,
  requestId,
  refetch,
}: {
  address: string;
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  requestId: number | null;
  refetch: any;
}) => {
  const chains = useChains();
  const chainId = useChainId();

  const chain = chains?.filter(_chain => _chain?.id === chainId)[0];

  const [requestDetails, setRequestDetails] = useState<RequestDetail[]>([]);

  useEffect(() => {
    const getRequestDetails = async () => {
      try {
        if (!address || !deployedContractAddress || deployedContractAbi || !requestId) return;

        const provider = new ethers.JsonRpcProvider(chain?.rpcUrls?.default?.http[0]);
        const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);

        const [depositPeriods, amounts] = await contract.unlockRequests(address, BigInt(requestId));

        const formattedDetails: RequestDetail[] = depositPeriods.map((period: bigint, index: number) => ({
          depositPeriod: Number(period),
          unlockAmount: amounts[index],
        }));

        setRequestDetails(formattedDetails);
      } catch (error) {
        console.error("Error getting request details:", error);
      }
    };

    getRequestDetails();
  }, [address, deployedContractAddress, deployedContractAbi, requestId, refetch]);

  return { requestDetails };
};
