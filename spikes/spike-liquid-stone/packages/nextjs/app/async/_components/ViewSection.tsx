"use client";

import { useEffect, useState } from "react";
import { Contract, ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { useTheme } from "next-themes";

import { useFetchContractData } from "~~/hooks/async/useFetchContractData";
import { useFetchLocks } from "~~/hooks/async/useFetchLocks";
import { useFetchUnlockRequests } from "~~/hooks/async/useFetchUnlockRequests";
import { useFetchRequestDetails } from "~~/hooks/async/useFetchRequestDetails";

import { useTransactor } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";
import { useWriteContract } from "wagmi";
import LoadingSpinner from "../../../components/general/LoadingSpinner";
import ContractValueBadge from "../../../components/general/ContractValueBadge";
import ActionCard from "~~/components/general/ActionCard";
import Input from "../../../components/general/Input";
import Button from "../../../components/general/Button";

import LockAction from "./LockAction";

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

    // Action Values
    // RequestUnlock State Variables
    const [inputPairs, setInputPairs] = useState([{ period: "", amount: "" }]);

    const [selectedRequestId, setSelectedRequestId] = useState<number | null>(null);

    // Unlock State Variables
    const [requestId, setRequestId] = useState("");

    // Action events for request unlock
    const handleInputChange = (
        index: number,
        field: "period" | "amount", // Union type for field
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

    useEffect(() => {
        setMounted(true);
    }, []);

    const { noticePeriod, currentPeriod } =
    useFetchContractData({
      deployedContractAddress,
      deployedContractAbi,
      dependencies: [refetch]
    });

    const { lockDatas } = useFetchLocks({
        address: address || "",
        deployedContractAddress,
        deployedContractAbi,
        refetch,
    });

    const { unlockRequests } = useFetchUnlockRequests({
        address: address || "",
        deployedContractAddress,
        deployedContractAbi,
        currentPeriod,
        noticePeriod,
        refetch
    });

    const { requestDetails } = useFetchRequestDetails({
        address: address || "",
        deployedContractAddress,
        deployedContractAbi,
        requestId: selectedRequestId,
        refetch
    });

    const writeTxn = useTransactor();
    const { writeContractAsync } = useWriteContract();


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

            writeTxn(makeUnlockRequestWithParams).then(data => {
                console.log("setting refresh", data);
                setRefetch(prev => !prev);
            });
        } catch (error) {
            console.error("Error handleUnlockRequest:", error);    
        }
    }

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

            writeTxn(makeUnlockWithParams).then(data => {
                console.log("setting refresh", data);
                setRefetch(prev => !prev);
            });
        } catch (error) {
            console.error("Error handleUnlock:", error);    
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
                        <ContractValueBadge name="Notice Period" value={`${noticePeriod} days`} />
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
                    <h2 className="text-xl font-bold mb-4">Locked Amount Table</h2>
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

                <div
                className={`${
                    resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
                } p-4 rounded-lg grid gap-3`}
                >
                    <h2 className="text-xl font-bold mb-4">Request ID Table</h2>
                    <table className="table w-full">
                        <thead>
                            <tr>
                                <th>Request ID</th>
                                <th>Unlock Amount</th>
                            </tr>
                        </thead>
                        <tbody>
                        {unlockRequests.map((row) => (
                            <tr key={row.requestId}
                            onClick={() => setSelectedRequestId(row.requestId)}
                            className="cursor-pointer hover:bg-gray-200"
                            >
                                <td>{row.requestId}</td>
                                <td>{row.unlockAmount.toString()}</td>
                            </tr>
                        ))}
                        </tbody>
                    </table>
                </div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                <div
                    className={`${
                        resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
                    } p-4 rounded-lg grid gap-3`}
                >
                    <h2 className="text-xl font-bold mb-4">Request Details</h2>

                    <table className="table w-full">
                        <thead>
                            <tr>
                                <th>Deposit Period</th>
                                <th>Unlock Amount</th>
                            </tr>
                        </thead>
                        <tbody>
                        { requestDetails.map((row) => (
                            <tr key={row.depositPeriod}>
                                <td>{row.depositPeriod}</td>
                                <td>{row.unlockAmount.toString()}</td>
                            </tr>
                        ))}
                        </tbody>
                    </table>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Lock */}
                <LockAction
                    address={address}
                    deployedContractAddress={deployedContractAddress}
                    deployedContractAbi={deployedContractAbi}
                    onRefetch={() => setRefetch((prev) => !prev)}
                />
                {/* Request Unlock */}
                <ActionCard key="1">
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
                {/* Unlock */}
                <ActionCard key="2">
                    <h2 className="text-xl font-bold mb-4">Unlock</h2>
                    <Input
                        type="text"
                        value={requestId}
                        placeholder="Enter Request ID"
                        onChangeHandler={value => setRequestId(value)}  
                    />
                    <Button text="Unlock" bgColor="blue" onClickHandler={handleUnlock} />
                </ActionCard>
            </div>
        </div>
    );
  };

  export default ViewSection;