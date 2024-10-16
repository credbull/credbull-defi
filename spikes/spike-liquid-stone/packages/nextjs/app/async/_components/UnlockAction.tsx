"use client";

import { useState } from "react";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useWriteContract } from "wagmi";
import { notification } from "~~/utils/scaffold-eth";

import ActionCard from "~~/components/general/ActionCard";
import Input from "../../../components/general/Input";
import Button from "../../../components/general/Button";

const UnlockAction = ({
    address,
    deployedContractAddress,
    deployedContractAbi,
    onRefetch
  }: {
    address: string | undefined;
    deployedContractAddress: string;
    deployedContractAbi: ContractAbi;
    onRefetch: () => void;
  }) => {

    const [requestId, setRequestId] = useState("");

    const writeTxn = useTransactor();
    const { writeContractAsync } = useWriteContract();

    const handleUnlock = async () => {
        try {
            if (!address || !requestId) {
                notification.error("Missing required fields");
                return;
            }

            const makeUnlockWithParams = () => writeContractAsync({
                address: deployedContractAddress,
                abi: deployedContractAbi,
                functionName: "unlock",
                args: [
                    address,
                    BigInt(requestId)
                ],
            });

            await writeTxn(makeUnlockWithParams);
            
            setRequestId("");

            onRefetch();
        } catch (error) {
            console.error("Error handleUnlock:", error);    
        }
    }

    return (
        <>
            <ActionCard key="2">
                <h2 className="text-xl font-bold mb-4">Unlock</h2>
                <Input
                    type="number"
                    value={requestId}
                    placeholder="Enter Request ID"
                    onChangeHandler={value => setRequestId(value)}  
                />
                <Button text="Unlock" bgColor="blue" onClickHandler={handleUnlock} />
            </ActionCard>
        </>
    )
};

export default UnlockAction;