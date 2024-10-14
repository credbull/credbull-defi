"use client";

import React, { useState } from "react";
import { useRequestData } from "~~/hooks/custom/useRequestData";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { MAX_PERIOD } from "~~/lib/constants";

interface RequestIdTableProps {
  proxyAddress: string;
  abi: ContractAbi;
  userAddress: string;
}

const RequestIdTable: React.FC<RequestIdTableProps> = ({
  proxyAddress,
  abi,
  userAddress,
}) => {
  const { rows, details, loading, fetchDetails, error } = useRequestData({
    proxyAddress,
    abi,
    userAddress,
    maxPeriod: MAX_PERIOD,
  });

  const [selectedRequestId, setSelectedRequestId] = useState<number | null>(null);

  const handleRowClick = (requestId: number) => {
    setSelectedRequestId(requestId);
    fetchDetails(requestId); // Fetch the details when a row is clicked
  };

  return (
    <div className="overflow-x-auto">
      <h2 className="text-lg font-bold mb-4">Request ID Table</h2>
      {error && <p className="text-red-500">{error}</p>}
      <table className="table w-full">
        <thead>
          <tr>
            <th>Request ID</th>
            <th>Unlock Amount</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={row.requestId}
              onClick={() => handleRowClick(row.requestId)}
              className="cursor-pointer hover:bg-gray-200"
            >
              <td>{row.requestId}</td>
              <td>{row.unlockAmount.toString()}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {selectedRequestId !== null && (
        <div className="mt-8">
          <h2 className="text-lg font-bold mb-4">Unlock Request Details</h2>
          {loading ? (
            <p>Loading...</p>
          ) : (
            <table className="table w-full">
              <thead>
                <tr>
                  <th>Deposit Period</th>
                  <th>Amount</th>
                </tr>
              </thead>
              <tbody>
                {details.map((detail, index) => (
                  <tr key={index}>
                    <td>{detail.depositPeriod}</td>
                    <td>{detail.amount.toString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
};

export default RequestIdTable;
