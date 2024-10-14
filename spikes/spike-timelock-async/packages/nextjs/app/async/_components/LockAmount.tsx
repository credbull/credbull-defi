"use client";

import React, { useState } from "react";
import { notification } from "~~/utils/scaffold-eth";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { useWriteContract } from "wagmi";

interface LockAmountProps {
    proxyAddress: string;
    abi: ContractAbi;
    userAddress: string;
}

const LockAmount: React.FC<LockAmountProps> = ({
    proxyAddress,
    abi,
    userAddress,
}) => {
  const [depositPeriod, setDepositPeriod] = useState<string>("");
  const [amount, setAmount] = useState<string>("");

  const { writeContractAsync, isPending } = useWriteContract();

  const handleButtonClick = async() => {
    if (!depositPeriod || !amount) {
        notification.error("Both Deposit Period and Amount are required!");
        return;
    }
    // add condition  
    // depositPeriod should be bigger than currentPeriod
    try {
        const tx = await writeContractAsync({
          address: proxyAddress,
          abi,
          functionName: "lock",
          args: [
            userAddress,
            BigInt(depositPeriod), // Convert to BigInt
            BigInt(amount), // Convert to BigInt
          ],
        });
  
        console.log("Transaction successful:", tx);
        notification.success("Amount locked successfully!");
    } catch (error) {
        console.error("Transaction failed:", error);
        // notification.error(`Transaction failed: ${error.message}`);
    }
  };

  return (
    <div className="flex items-center gap-4">
      {/* Deposit Period Input */}
      <input
        type="number"
        placeholder="Deposit Period"
        value={depositPeriod}
        onChange={(e) => setDepositPeriod(e.target.value)}
        className="input input-bordered w-full max-w-xs"
      />

      {/* Amount Input */}
      <input
        type="number"
        placeholder="Amount"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        className="input input-bordered w-full max-w-xs"
      />

      {/* Lock Button */}
      <button
        onClick={handleButtonClick}
        className="btn btn-primary"
      > {
         isPending ? <span className="loading loading-spinner loading-sm"></span>
         : "Lock"
        }
      </button>
    </div>
  );
};

export default LockAmount;
