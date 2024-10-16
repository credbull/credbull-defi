"use client";

import { useState } from "react";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useWriteContract } from "wagmi";
import { notification } from "~~/utils/scaffold-eth";

import ActionCard from "~~/components/general/ActionCard";
import Input from "../../../components/general/Input";
import Button from "../../../components/general/Button";

const SetCurrentPeriod = ({
    deployedContractAddress,
    deployedContractAbi,
    onRefetch
  }: {
    deployedContractAddress: string;
    deployedContractAbi: ContractAbi;
    onRefetch: () => void;
  }) => {
    const [currentPeriod, setCurrentPeriod] = useState("");

    const writeTxn = useTransactor();
    const { writeContractAsync } = useWriteContract();

    const handleCurrentPeriod = async () => {
        try {
            if (!currentPeriod) {
                notification.error("Missing required fields");
                return;
            }

            const makeSetCurrentPeriodWithParams = () => writeContractAsync({
                address: deployedContractAddress,
                abi: deployedContractAbi,
                functionName: "setCurrentPeriod",
                args: [
                    BigInt(currentPeriod)
                ],
            });

            await writeTxn(makeSetCurrentPeriodWithParams);
            onRefetch();
        } catch (error) {
            console.error("Error handleCurrentPeriod:", error);    
        }
    }

    return (
        <>
            <ActionCard>
                <h2 className="text-xl font-bold mb-4">Set CurrentPeriod</h2>
                <Input
                    type="text"
                    value={currentPeriod}
                    placeholder="Enter Time Period"
                    onChangeHandler={value => setCurrentPeriod(value)}  
                />
                <Button text="SetCurrentPeriod" bgColor="blue" onClickHandler={handleCurrentPeriod} />
            </ActionCard>
        </>
    )
}

export default SetCurrentPeriod;