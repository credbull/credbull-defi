"use client";

import React, { useEffect, useState } from "react";
import { useReadContract } from "wagmi";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

interface LockedAmountTableProps {
  proxyAddress: string;
  abi: ContractAbi;
  userAddress: string;
  maxPeriod: number;
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
  maxPeriod,
}) => {
  const [rows, setRows] = useState<TableRow[]>([]);

  // Create one hook per deposit period for lockedAmount
  const lockedAmountHooks = Array.from({ length: maxPeriod + 1 }, (_, period) =>
    useReadContract({
      address: proxyAddress,
      abi,
      functionName: "lockedAmount",
      args: [userAddress, BigInt(period)],
    })
  );

  // Create one hook per deposit period for maxRequestUnlock
  const maxRequestUnlockHooks = Array.from(
    { length: maxPeriod + 1 },
    (_, period) =>
      useReadContract({
        address: proxyAddress,
        abi,
        functionName: "maxRequestUnlock",
        args: [userAddress, BigInt(period)],
      })
  );

  // Create one hook per deposit period for unlockRequestAmount
  const unlockRequestAmountHooks = Array.from(
    { length: maxPeriod + 1 },
    (_, period) =>
      useReadContract({
        address: proxyAddress,
        abi,
        functionName: "unlockRequestAmountByDepositPeriod",
        args: [userAddress, BigInt(period)],
      })
  );

  useEffect(() => {
    const fetchData = async () => {
      const newRows: TableRow[] = [];

      for (let period = 0; period <= maxPeriod; period++) {
        try {
          const { data: locked } = lockedAmountHooks[period];
          const lockedAmount = BigInt(locked || 0);

          if (lockedAmount > 0) {
            const { data: maxUnlock } = maxRequestUnlockHooks[period];
            const maxRequestUnlock = BigInt(maxUnlock || 0);

            const { data: unlockRequest } = unlockRequestAmountHooks[period];
            const unlockRequestAmount = BigInt(unlockRequest || 0);

            newRows.push({
              depositPeriod: period,
              lockedAmount,
              maxRequestUnlock,
              unlockRequestAmount,
            });
          }
        } catch (error) {
          console.error(`Error fetching data for period ${period}:`, error);
        }
      }

      setRows(newRows);
    };

    fetchData();
  }, [lockedAmountHooks, maxRequestUnlockHooks, unlockRequestAmountHooks]);

  return (
    <div className="overflow-x-auto">
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
