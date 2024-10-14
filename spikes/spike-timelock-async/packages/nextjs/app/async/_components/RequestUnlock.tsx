"use client";

import React, { useState } from "react";
import { useWriteContract } from "wagmi";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { notification } from "~~/utils/scaffold-eth";

interface RequestUnlockProps {
  proxyAddress: string;
  abi: ContractAbi;
  userAddress: string;
}

const RequestUnlock: React.FC<RequestUnlockProps> = ({
  proxyAddress,
  abi,
  userAddress,
}) => {
  const [inputPairs, setInputPairs] = useState([{ period: "", amount: "" }]);

  const { writeContractAsync, isPending } = useWriteContract();

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

  const handleUnlockRequest = async () => {
    try {
      const depositPeriods = inputPairs.map((pair) => BigInt(pair.period));
      const amounts = inputPairs.map((pair) => BigInt(pair.amount));

      
      const tx = await writeContractAsync({
        address: proxyAddress,
        abi,
        functionName: "requestUnlock",
        args: [userAddress, depositPeriods, amounts],
      });

      console.log("Transaction successful:", tx);
      notification.success("Unlock request submitted successfully!");
    } catch (error) {
      console.error("Transaction failed:", error);
      // notification.error(`Transaction failed: ${error.message}`);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      {inputPairs.map((pair, index) => (
        <div key={index} className="flex items-center gap-4">
          <input
            type="number"
            placeholder="Deposit Period"
            value={pair.period}
            onChange={(e) =>
              handleInputChange(index, "period", e.target.value)
            }
            className="input input-bordered w-full max-w-xs"
          />
          <input
            type="number"
            placeholder="Amount"
            value={pair.amount}
            onChange={(e) =>
              handleInputChange(index, "amount", e.target.value)
            }
            className="input input-bordered w-full max-w-xs"
          />
        </div>
      ))}

      <div className="flex items-center gap-4 mt-4">
        <button onClick={handleAddInput} className="btn btn-success">
          + Add Input
        </button>
        <button onClick={handleRemoveInput} className="btn btn-danger">
          - Remove Input
        </button>
      </div>

      <button
        onClick={handleUnlockRequest}
        className="btn btn-primary mt-4 w-auto px-8"
        disabled={isPending}
      >
        {isPending ? (
          <span className="loading loading-spinner loading-sm"></span>
        ) : (
          "Request Unlock"
        )}
      </button>
    </div>
  );
};

export default RequestUnlock;
