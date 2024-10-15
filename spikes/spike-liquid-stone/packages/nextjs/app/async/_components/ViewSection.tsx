"use client";

import { useEffect, useState } from "react";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { useTheme } from "next-themes";

import { useFetchContractData } from "~~/hooks/async/useFetchContractData";
import { useFetchLocks } from "~~/hooks/async/useFetchLocks";
import { useFetchUnlockRequests } from "~~/hooks/async/useFetchUnlockRequests";
import { useFetchRequestDetails } from "~~/hooks/async/useFetchRequestDetails";

import LoadingSpinner from "../../../components/general/LoadingSpinner";
import ContractValueBadge from "../../../components/general/ContractValueBadge";

import LockAction from "./LockAction";
import RequestUnlockAction from "./RequestUnlockAction";
import UnlockAction from "./UnlockAction";

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
    const [selectedRequestId, setSelectedRequestId] = useState<number | null>(null);

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
                <RequestUnlockAction
                    address={address}
                    deployedContractAddress={deployedContractAddress}
                    deployedContractAbi={deployedContractAbi}
                    onRefetch={() => setRefetch((prev) => !prev)}
                />
                {/* Unlock */}
                <UnlockAction
                    address={address}
                    deployedContractAddress={deployedContractAddress}
                    deployedContractAbi={deployedContractAbi}
                    onRefetch={() => setRefetch((prev) => !prev)}
                />
            </div>
        </div>
    );
  };

  export default ViewSection;