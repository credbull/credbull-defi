import { useEffect, useState } from "react";
import { useReadContract } from "wagmi";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

export const useFetchContractData = ({
  deployedContractAddress,
  deployedContractAbi,
  dependencies = [],
}: {
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  dependencies: [any] | [];
}) => {
  const [noticePeriod, setNoticePeriod] = useState<number>(0);
  const [currentPeriod, setCurrentPeriod] = useState<number>(0);
  const [minUnlockPeriod, setMinUnlockPeriod] = useState<number>(0);

  const { refetch: refetchNoticePeriod } = useReadContract({
    address: deployedContractAddress,
    functionName: "noticePeriod",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchCurrentPeriod } = useReadContract({
    address: deployedContractAddress,
    functionName: "currentPeriod",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchMinUnlockPeriod } = useReadContract({
    address: deployedContractAddress,
    functionName: "minUnlockPeriod",
    abi: deployedContractAbi,
    args: [],
  });

  const fetchData = async () => {
    try {
      const noticePeriodData = await refetchNoticePeriod();
      setNoticePeriod(Number(noticePeriodData?.data));

      const currentPeriodData = await refetchCurrentPeriod();
      setCurrentPeriod(Number(currentPeriodData?.data));

      const minUnlockPeriodData = await refetchMinUnlockPeriod();
      setMinUnlockPeriod(Number(minUnlockPeriodData?.data));
    } catch (error) {
      console.error("Error fetching contract data:", error);
    }
  };

  useEffect(() => {
    fetchData();
  }, [refetchNoticePeriod, refetchCurrentPeriod, refetchMinUnlockPeriod, ...dependencies]);

  return {
    noticePeriod,
    currentPeriod,
    minUnlockPeriod,
  };
};
