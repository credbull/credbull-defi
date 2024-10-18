"use client";

import React, { useEffect, useState } from "react";
import ContractValueBadge from "../../../components/general/ContractValueBadge";
import LoadingSpinner from "../../../components/general/LoadingSpinner";
import LockAction from "./LockAction";
import RequestUnlockAction from "./RequestUnlockAction";
import SetCurrentPeriod from "./SetCurrentPeriod";
import UnlockAction from "./UnlockAction";
import { useTheme } from "next-themes";
import { useAccount } from "wagmi";
import { useFetchContractData } from "~~/hooks/async/useFetchContractData";
import { useFetchLocks } from "~~/hooks/async/useFetchLocks";
import { useFetchRequestDetails } from "~~/hooks/async/useFetchRequestDetails";
import { useFetchUnlockRequests } from "~~/hooks/async/useFetchUnlockRequests";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const contractsData = getAllContracts();

const ViewSection = () => {
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [refetch, setRefetch] = useState(false);

  const { address } = useAccount();
  const contractNames = Object.keys(contractsData) as ContractName[];

  const { data: implementationContractData, isLoading: implementationContractLoading } = useDeployedContractInfo(
    contractNames[6],
  );
  const { data: proxyContractData, isLoading: proxyContractLoading } = useDeployedContractInfo(contractNames[7]);

  // Action Values
  const [expandedRowId, setExpandedRowId] = useState<number | null>(null);
  const [selectedRequestId, setSelectedRequestId] = useState<string>("");

  useEffect(() => {
    setMounted(true);
  }, []);

  const { noticePeriod, currentPeriod, minUnlockPeriod } = useFetchContractData({
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    dependencies: [refetch],
  });

  const { lockDatas } = useFetchLocks({
    address: address || "",
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    refetch,
  });

  const { unlockRequests } = useFetchUnlockRequests({
    address: address || "",
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    currentPeriod,
    noticePeriod,
    refetch,
  });

  const { requestDetails } = useFetchRequestDetails({
    address: address || "",
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    requestId: expandedRowId,
    refetch,
  });

  if (!mounted) {
    return <LoadingSpinner />;
  }

  return (
    <div className={`container mx-auto p-6 ${resolvedTheme === "dark" ? "text-white" : "text-black"}`}>
      <div
        className={`${
          resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
        } p-4 rounded-lg mb-6 flex`}
      >
        <div>
          <h2 className="text-xl font-bold mb-4">Contract Details</h2>
          {implementationContractLoading || proxyContractLoading ? (
            <LoadingSpinner />
          ) : (
            <div className="flex flex-wrap gap-4">
              <ContractValueBadge name="Notice Period" value={`${noticePeriod} days`} />
              <ContractValueBadge name="Current Period" value={currentPeriod} />
              <ContractValueBadge name="Min Unlock Period" value={minUnlockPeriod} />
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6 mt-6">
        <div
          className={`${resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"} p-4 rounded-lg`}
          style={{ maxHeight: "400px", overflowY: "auto" }}
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
              {lockDatas.map(row => (
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

        {/* Request ID Table with Expandable Rows */}
        <div
          className={`${resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"} p-4 rounded-lg`}
          style={{ maxHeight: "400px", overflowY: "auto" }}
        >
          <h2 className="text-xl font-bold mb-4">Request ID Table</h2>
          <table className="table w-full">
            <thead>
              <tr>
                <th>Request ID (Unlock Period)</th>
                <th>Unlock Amount</th>
              </tr>
            </thead>
            <tbody>
              {unlockRequests.map(row => (
                <React.Fragment key={`request-${row.requestId}`}>
                  <tr
                    onClick={() => {
                      setExpandedRowId(expandedRowId === row.requestId ? null : row.requestId);
                      setSelectedRequestId(row.requestId.toString());
                    }}
                    className="cursor-pointer hover:bg-gray-200"
                  >
                    <td>{row.requestId}</td>
                    <td>{row.unlockAmount.toString()}</td>
                  </tr>

                  {expandedRowId === row.requestId && (
                    <tr key={`detail-${row.requestId}`}>
                      <td colSpan={2}>
                        <div className="p-4 bg-gray-100 rounded-lg">
                          <table className="table w-full">
                            <thead>
                              <tr>
                                <th>Deposit Period</th>
                                <th>Unlock Amount</th>
                              </tr>
                            </thead>
                            <tbody>
                              {requestDetails.map(detail => (
                                <tr key={`requestDetail-${detail.depositPeriod}`}>
                                  <td>{detail.depositPeriod}</td>
                                  <td>{detail.unlockAmount.toString()}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* Lock */}
        <LockAction
          address={address}
          deployedContractAddress={proxyContractData?.address || ""}
          deployedContractAbi={implementationContractData?.abi as ContractAbi}
          onRefetch={() => setRefetch(prev => !prev)}
        />
        {/* Request Unlock */}
        <RequestUnlockAction
          address={address}
          deployedContractAddress={proxyContractData?.address || ""}
          deployedContractAbi={implementationContractData?.abi as ContractAbi}
          currentPeriod={currentPeriod}
          onRefetch={() => setRefetch(prev => !prev)}
        />
        {/* Unlock */}
        <UnlockAction
          address={address}
          deployedContractAddress={proxyContractData?.address || ""}
          deployedContractAbi={implementationContractData?.abi as ContractAbi}
          requestId={selectedRequestId}
          onRefetch={() => setRefetch(prev => !prev)}
        />

        {/* SetCurrentPeriod */}
        <SetCurrentPeriod
          address={address}
          deployedContractAddress={proxyContractData?.address || ""}
          deployedContractAbi={implementationContractData?.abi as ContractAbi}
          onRefetch={() => setRefetch(prev => !prev)}
        />
      </div>
    </div>
  );
};

export default ViewSection;
