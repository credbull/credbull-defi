import React, { useState } from 'react';
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { useWriteContract } from "wagmi";
import { notification } from "~~/utils/scaffold-eth";

interface SetCurrentPeriodProps {
    proxyAddress: string;
    abi: ContractAbi;
    refetchCurrentPeriod: () => Promise<void>; // New prop for refetching
}

const SetCurrentPeriod: React.FC<SetCurrentPeriodProps> = ({
    proxyAddress,
    abi,
    refetchCurrentPeriod,
}) => {
  const [currentPeriod, setCurrentPeriod] = useState<string>('');

  const { writeContractAsync, isPending } = useWriteContract();

  const handleButtonClick = async () => {
    if (!currentPeriod) {
        notification.error("Current Period is required!"); // Optional
        return;
    }
    
    try {
        const tx = await writeContractAsync({
            address: proxyAddress,
            functionName: "setCurrentPeriod",
            abi,
            args: [BigInt(currentPeriod)], // Use BigInt for uint256 values
        });

        console.log("Transaction successful:", tx);
        notification.success("Current period updated successfully!");

        await refetchCurrentPeriod();
    } catch (error) {
        console.error("Transaction failed:", error);
        // notification.error(`Transaction failed: ${error.message}`); // Optional        
    }
  };

  return (
    <div className="flex items-center gap-4">
      <input
        type="number"
        placeholder="Current Period"
        value={currentPeriod}
        onChange={(e) => setCurrentPeriod(e.target.value)}
        className="input input-bordered w-full max-w-xs"
      />
      <button onClick={handleButtonClick} className="btn btn-primary" disabled={isPending}>
        {isPending ? <span className="loading loading-spinner loading-sm"></span> : "SetCurrentPeriod"}
      </button>
    </div>
  );
};

export default SetCurrentPeriod;