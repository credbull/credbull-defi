"use client";

import React, { useEffect, useState } from "react";
import { useReadContract } from "wagmi";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

interface RequestIdTableProps {
  proxyAddress: string;
  abi: ContractAbi;
  userAddress: string;
  maxRequestId: number;
}

interface TableRow {
  requestId: number;
  unlockAmount: bigint;
}

const RequestIdTable: React.FC<RequestIdTableProps> = ({
  proxyAddress,
  abi,
  userAddress,
  maxRequestId,
}) => {
  const [rows, setRows] = useState<TableRow[]>([]);

  const unlockAmountHooks = Array.from(
    { length: maxRequestId + 1 },
    (_, requestId) =>
      useReadContract({
        address: proxyAddress,
        abi,
        functionName: "unlockRequestAmount",
        args: [userAddress, BigInt(requestId)],
      })
  );

  useEffect(() => {
    const fetchData = async () => {
      const newRows: TableRow[] = [];

      for (let requestId = 0; requestId <= maxRequestId; requestId++) {
        try {
          const { data: unlockAmount } = unlockAmountHooks[requestId];
          const amount = BigInt(unlockAmount || 0);

          if (amount > 0) {
            newRows.push({
              requestId,
              unlockAmount: amount,
            });
          }
        } catch (error) {
          console.error(`Error fetching data for requestId ${requestId}:`, error);
        }
      }

      setRows(newRows);
    };

    fetchData();
  }, [unlockAmountHooks]);

  return (
    <div className="overflow-x-auto">
      <table className="table w-full">
        <thead>
          <tr>
            <th>Request ID</th>
            <th>Unlock Amount</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.requestId}>
              <td>{row.requestId}</td>
              <td>{row.unlockAmount.toString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default RequestIdTable;
