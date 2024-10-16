"use client";

import { useState } from "react";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useWriteContract } from "wagmi";
import { notification } from "~~/utils/scaffold-eth";
import { MAX_PERIODS } from "~~/utils/async/config";

import ActionCard from "~~/components/general/ActionCard";
import Input from "../../../components/general/Input";
import Button from "../../../components/general/Button";

const LockAction = ({
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
    const [lockAmount, setLockAmount] = useState("");
    const [lockDepositPeriod, setLockDepositPeriod] = useState("");

    const writeTxn = useTransactor();
    const { writeContractAsync } = useWriteContract();

    const handleLock = async () => {
        if (!address || !lockAmount || !lockDepositPeriod) {
            notification.error("Missing required fields");
            return;
        }
        
        if (Number(lockDepositPeriod) > MAX_PERIODS) {
            notification.error(`Deposit period must be less than or equal to ${MAX_PERIODS}(MAX_PERIODS).`);
            return;
        }

        try {
            const makeLockWithParams = () =>
                writeContractAsync({
                    address: deployedContractAddress,
                    abi: deployedContractAbi,
                    functionName: "lock",
                    args: [
                        address,
                        BigInt(lockDepositPeriod),
                        BigInt(lockAmount),
                    ],
                });

            await writeTxn(makeLockWithParams);

            setLockAmount("");
            setLockDepositPeriod("");

            onRefetch();
        } catch (error) {
            console.error("Error during lock:", error);
        }
    };

    return (
        <>
            <ActionCard>
                <h2 className="text-xl font-bold mb-4">Lock</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <Input
                        type="number"
                        value={lockDepositPeriod}
                        placeholder="Enter Deposit Period"
                        onChangeHandler={value => setLockDepositPeriod(value)}
                    />
                    <Input
                        type="number"
                        value={lockAmount}
                        placeholder="Enter Lock Amount"
                        onChangeHandler={value => setLockAmount(value)}
                    />
                </div>

                <Button text="Lock" bgColor="blue" onClickHandler={handleLock} />
            </ActionCard> 
        </>
    )
};

export default LockAction;