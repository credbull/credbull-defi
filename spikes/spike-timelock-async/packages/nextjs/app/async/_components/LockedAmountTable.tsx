"use client";

import React, { useEffect, useState } from "react";
import { useReadContract } from "wagmi";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { MAX_PERIOD } from '~~/lib/constants';

interface LockedAmountTableProps {
  proxyAddress: string;
  abi: ContractAbi;
  userAddress: string;
}

interface TableRow {
  depositPeriod: number;
  lockedAmount: bigint;
  maxRequestUnlock: bigint;
  unlockRequestAmount: bigint;
}

const LockedAmountTable: React.FC<LockedAmountTableProps> = ({
  proxyAddress,
  abi,
  userAddress,
}) => {
  const [rows, setRows] = useState<TableRow[]>([]);

  const lockedAmountHooks = Array.from({ length: MAX_PERIOD + 1 }, (_, period) =>
    useReadContract({
      address: proxyAddress,
      abi,
      functionName: "lockedAmount",
      args: [userAddress, BigInt(period)]
    })
  );

  const maxRequestUnlockHooks = Array.from({ length: MAX_PERIOD + 1 }, (_, period) =>
    useReadContract({
      address: proxyAddress,
      abi,
      functionName: "maxRequestUnlock",
      args: [userAddress, BigInt(period)]
    })
  );

  const unlockRequestAmountHooks = Array.from({ length: MAX_PERIOD + 1 }, (_, period) =>
    useReadContract({
      address: proxyAddress,
      abi,
      functionName: "unlockRequestAmountByDepositPeriod",
      args: [userAddress, BigInt(period)]
    })
  );

  useEffect(() => {
    const fetchData = async () => {
      try {
        const newRows: TableRow[] = [];

        const promises = Array.from({ length: MAX_PERIOD + 1 }, async (_, period) => {
          const { data: locked } = await lockedAmountHooks[period].refetch();
          const lockedAmount = BigInt(locked || 0);

          if (lockedAmount > 0) {
            const { data: maxUnlock } = await maxRequestUnlockHooks[period].refetch();
            const { data: unlockRequest } = await unlockRequestAmountHooks[period].refetch();

            const maxRequestUnlock = BigInt(maxUnlock || 0);
            const unlockRequestAmount = BigInt(unlockRequest || 0);

            newRows.push({
              depositPeriod: period,
              lockedAmount,
              maxRequestUnlock,
              unlockRequestAmount,
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
  }, [lockedAmountHooks, maxRequestUnlockHooks, unlockRequestAmountHooks]);

  return (
    <div className="overflow-x-auto">
      <h2 className="text-lg font-bold mb-4">Locked Amount Table</h2>
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
          {rows.map((row) => (
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
  );
};

export default LockedAmountTable;
