"use client";

import { useEffect, useState } from "react";
import { Contract, ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { useTheme } from "next-themes";
import { useFetchContractData } from "~~/hooks/async/useFetchContractData";
import { useFetchLockDatas } from "~~/hooks/async/useFetchLockDatas";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";
import { useChainId, useWriteContract } from "wagmi";
import LoadingSpinner from "../../../components/general/LoadingSpinner";
import ContractValueBadge from "../../../components/general/ContractValueBadge";
import ActionCard from "~~/components/general/ActionCard";
import Input from "../../../components/general/Input";
import Button from "../../../components/general/Button";

const ViewSection = ({
    address,
    deployedContractAddress,
    deployedContractAbi,
    deployedContractLoading
  }: {
    address: string | undefined;
    deployedContractAddress: string;
    deployedContractAbi: ContractAbi;
    deployedContractLoading: boolean;
  }) => {
    const { resolvedTheme } = useTheme();
    const [mounted, setMounted] = useState(false);
    const [refetch, setRefetch] = useState(false);

    //Action Values
    const [lockAmount, setLockAmount] = useState("");
    const [lockDepositPeriod, setLockDepositPeriod] = useState("");

    useEffect(() => {
        setMounted(true);
    }, []);

    const { noticePeriod, currentPeriod } =
    useFetchContractData({
      deployedContractAddress,
      deployedContractAbi,
      dependencies: [refetch]
    });

    const { lockDatas } = useFetchLockDatas({
        address: address || "",
        deployedContractAddress,
        deployedContractAbi,
        refetch,
    });

    const writeTxn = useTransactor();
    const { writeContractAsync } = useWriteContract();

    const handleLock = async () => {
        if (!address || !lockAmount) {
            notification.error("Missing required fields");
            return;
        }

        try {
            const makeLockWithParams = () => writeContractAsync({
                address: deployedContractAddress,
                abi: deployedContractAbi,
                functionName: "lock",
                args: [
                  address,
                  BigInt(lockDepositPeriod), // Convert to BigInt
                  BigInt(lockAmount), // Convert to BigInt
                ],
            });

            writeTxn(makeLockWithParams).then(data => {
                console.log("setting refresh", data);
                setRefetch(prev => !prev);
            });
        } catch (error) {
            console.error("Error handleLock:", error);    
        }
    }

    if (!mounted) {
        return <LoadingSpinner />;
    }
      
    return (
        <div className={`container mx-auto p-6 ${resolvedTheme === "dark" ? "text-white" : "text-black"}`}>
            <div
            className={`${resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"} p-4 rounded-lg mb-6`}
            >     
                <h2 className="text-xl font-bold mb-4">Contract Details</h2>
                {deployedContractLoading ? (
                    <LoadingSpinner />
                    ) : (
                    <div className="flex flex-wrap gap-4">
                        <ContractValueBadge name="Frequency" value={`${noticePeriod} days`} />
                        <ContractValueBadge name="Current Period" value={currentPeriod} />
                    </div>
                    )}
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                <div
                className={`${
                    resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
                } p-4 rounded-lg grid gap-3`}
                >
                    <h2 className="text-xl font-bold mb-4">Deposit Pools</h2>
                    <table className="table w-full">
                        <thead>
                        <tr>
                            <th>Deposit Period</th>
                            <th>Locked Amount</th>
                            <th>Max Request Unlock</th>
                            <th>Unlock Request Amount</th>
                        </tr>
                        </thead>
                        <tbody>
                        {lockDatas.map((row) => (
                            <tr key={row.depositPeriod}>
                            <td>{row.depositPeriod}</td>
                            <td>{row.lockedAmount.toString()}</td>
                            <td>{row.maxRequestUnlock.toString()}</td>
                            <td>{row.unlockRequestAmount.toString()}</td>
                            </tr>
                        ))}
                        </tbody>
                    </table>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Lock */}
                <ActionCard>
                    <h2 className="text-xl font-bold mb-4">Lock</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <Input
                            type="text"
                            value={lockDepositPeriod}
                            placeholder="Enter Deposit Period"
                            onChangeHandler={value => setLockDepositPeriod(value)}
                        />
                        <Input
                            type="text"
                            value={lockAmount}
                            placeholder="Enter Lock Amount"
                            onChangeHandler={value => setLockAmount(value)}
                        />
                    </div>

                    <Button text="Lock" bgColor="blue" onClickHandler={handleLock} />

                </ActionCard>
                {/* Request Unlock */}
                <ActionCard>
                    <h2 className="text-xl font-bold mb-4">Request Unlock</h2>
                </ActionCard>
                {/* Unlock */}
                <ActionCard>
                    <h2 className="text-xl font-bold mb-4">Unlock</h2>
                </ActionCard>
            </div>
        </div>
    );
  };

  export default ViewSection;