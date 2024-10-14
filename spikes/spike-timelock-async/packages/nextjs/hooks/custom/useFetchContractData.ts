import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { useReadContract } from "wagmi";
import { useEffect, useState } from "react";

export const useFetchContractData = ({
    deployedContractAddress,
    deployedContractAbi
}: {
    deployedContractAddress: string;
    deployedContractAbi: ContractAbi;
}) => {
    const [noticePeriod, setNoticePeriod] = useState<number>(0);
    const [currentPeriod, setCurrentPeriod] = useState<number>(0);

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

    const fetchData = async() => {
        try {
            const noticePeriodData = await refetchNoticePeriod();
            setNoticePeriod(Number(noticePeriodData?.data));

            const currentPeriodData = await refetchCurrentPeriod();
            setCurrentPeriod(Number(currentPeriodData?.data));
        } catch (error) {
            console.error("Error fetching contract data:", error);
        }
    };

    useEffect(() => {
        fetchData();
    }, [refetchNoticePeriod, refetchCurrentPeriod]);

    return {
        noticePeriod,
        currentPeriod,
        refetchCurrentPeriod: async () => {
            const currentPeriodData = await refetchCurrentPeriod();
            setCurrentPeriod(Number(currentPeriodData?.data));
        },
    };
}