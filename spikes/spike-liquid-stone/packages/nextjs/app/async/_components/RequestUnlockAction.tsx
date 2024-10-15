"use client";

import { useState } from "react";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useWriteContract } from "wagmi";
import { notification } from "~~/utils/scaffold-eth";

import ActionCard from "~~/components/general/ActionCard";
import Input from "../../../components/general/Input";
import Button from "../../../components/general/Button";

const RequestUnlockAction = ({
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

    const [inputPairs, setInputPairs] = useState([{ period: "", amount: "" }]);
    
    const writeTxn = useTransactor();
    const { writeContractAsync } = useWriteContract();

    const handleInputChange = (
        index: number,
        field: "period" | "amount",
        value: string
    ) => {
        const updatedPairs = [...inputPairs];
        updatedPairs[index][field] = value;
        setInputPairs(updatedPairs);
    };

    const handleAddInput = () => {
        setInputPairs([...inputPairs, { period: "", amount: "" }]);
    };    

    const handleRemoveInput = () => {
        if (inputPairs.length > 1) {
            setInputPairs(inputPairs.slice(0, -1));
        }
    };

    const handleUnlockRequest = async () => {
        try {
            if (!address) {
                notification.error("Missing required fields");
                return;
            }

            const depositPeriodsForUnlockRequest = inputPairs.map((pair) => BigInt(pair.period));
            const amountsForUnlockRequest = inputPairs.map((pair) => BigInt(pair.amount));

            const makeUnlockRequestWithParams = () => writeContractAsync({
                address: deployedContractAddress,
                abi: deployedContractAbi,
                functionName: "requestUnlock",
                args: [
                  address,
                  depositPeriodsForUnlockRequest,
                  amountsForUnlockRequest,
                ],
            });
            
            await writeTxn(makeUnlockRequestWithParams);
            onRefetch();
        } catch (error) {
            console.error("Error handleUnlockRequest:", error);    
        }
    }

    return (
    <>
    <ActionCard>
        <h2 className="text-xl font-bold mb-4">Request Unlock</h2>
        {inputPairs.map((pair, index) => (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3" key={index}>
                <Input
                    type="text"
                    value={pair.period}
                    placeholder="Enter Deposit Period"
                    onChangeHandler={value => handleInputChange(index, "period", value)}
                />
                <Input
                    type="text"
                    value={pair.amount}
                    placeholder="Enter Amount"
                    onChangeHandler={value => handleInputChange(index, "amount", value)}
                />
            </div>
        ))}

        <div className="flex items-center gap-4 mb-4">
            <Button text="+ Add Input" bgColor="green" onClickHandler={handleAddInput} />
            <Button text="- Remove Input" bgColor="yellow" onClickHandler={handleRemoveInput} />
        </div>

        <Button text="Request Unlock" bgColor="blue" onClickHandler={handleUnlockRequest} />
    </ActionCard>    
    </>
    )
}

export default RequestUnlockAction;