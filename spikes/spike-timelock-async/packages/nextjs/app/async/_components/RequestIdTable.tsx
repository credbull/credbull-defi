"use client";

import React, { useEffect, useState } from "react";
import { useReadContract } from "wagmi";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { MAX_PERIOD } from '~~/lib/constants';

interface RequestIdTableProps {
  proxyAddress: string;
  abi: ContractAbi;
  userAddress: string;
}

interface TableRow {
  requestId: number;
  unlockAmount: bigint;
}

const RequestIdTable: React.FC<RequestIdTableProps> = ({
  proxyAddress,
  abi,
  userAddress
}) => {
  const [rows, setRows] = useState<TableRow[]>([]);

  const unlockRequestAmountHooks = Array.from({ length: MAX_PERIOD + 1 }, (_, requestId) =>
    useReadContract({
      address: proxyAddress,
      abi,
      functionName: "unlockRequestAmount",
      args: [userAddress, BigInt(requestId)]
    })
  );

  useEffect(() => {
    const fetchData = async () => {
      try {
        const newRows: TableRow[] = [];

        const promises = Array.from({ length: MAX_PERIOD + 1 }, async (_, requestId) => {
          const { data } = await unlockRequestAmountHooks[requestId].refetch();
          const amount = BigInt(data || 0);

          if (amount > 0) {
            newRows.push({
              requestId,
              unlockAmount: amount,
            });
          }
        });

        await Promise.all(promises);
        setRows(newRows);
      } catch (error) {
        console.error("Error fetching data:", error);
      }
    };

    fetchData();
  }, [unlockRequestAmountHooks]);

  return (
    <div className="overflow-x-auto">
      <h2 className="text-lg font-bold mb-4">Request ID Table</h2>
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
