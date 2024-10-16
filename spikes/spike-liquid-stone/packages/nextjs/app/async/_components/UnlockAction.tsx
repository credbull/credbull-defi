"use client";

import { useState, useEffect } from "react";
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
    requestId,
    onRefetch
  }: {
    address: string | undefined;
    deployedContractAddress: string;
    deployedContractAbi: ContractAbi;
    requestId: string;
    onRefetch: () => void;
  }) => {

    const [localRequestId, setLocalRequestId] = useState(requestId);

    const writeTxn = useTransactor();
    const { writeContractAsync } = useWriteContract();

    useEffect(() => {
        setLocalRequestId(requestId);
    }, [requestId]);

    const handleUnlock = async () => {
        try {
            if (!address || !localRequestId) {
                notification.error("Missing required fields");
                return;
            }

            const makeUnlockWithParams = () => writeContractAsync({
                address: deployedContractAddress,
                abi: deployedContractAbi,
                functionName: "unlock",
                args: [
                    address,
                    BigInt(localRequestId)
                ],
            });

            await writeTxn(makeUnlockWithParams);
            
            setLocalRequestId("");

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
                    onChangeHandler={value => setLocalRequestId(value)}  
                />
                <Button text="Unlock" bgColor="blue" onClickHandler={handleUnlock} />
            </ActionCard>
        </>
    )
};

export default UnlockAction;