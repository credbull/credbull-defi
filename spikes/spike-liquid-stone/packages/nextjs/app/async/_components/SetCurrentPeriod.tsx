"use client";

import { useState } from "react";
import Button from "../../../components/general/Button";
import Input from "../../../components/general/Input";
import { useWriteContract } from "wagmi";
import ActionCard from "~~/components/general/ActionCard";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { MAX_PERIODS } from "~~/utils/async/config";
import { notification } from "~~/utils/scaffold-eth";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

const SetCurrentPeriod = ({
  address,
  deployedContractAddress,
  deployedContractAbi,
  onRefetch,
}: {
  address: string | undefined;
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  onRefetch: () => void;
}) => {
  const [currentPeriod, setCurrentPeriod] = useState("");

  const writeTxn = useTransactor();
  const { writeContractAsync } = useWriteContract();

  const handleCurrentPeriod = async () => {
    try {
      if (!address || !currentPeriod) {
        notification.error("Missing required fields");
        return;
      }

      if (Number(currentPeriod) > MAX_PERIODS) {
        notification.error(`Current period must be less than or equal to ${MAX_PERIODS}(MAX_PERIODS).`);
        return;
      }

      const makeSetCurrentPeriodWithParams = () =>
        writeContractAsync({
          address: deployedContractAddress,
          abi: deployedContractAbi,
          functionName: "setCurrentPeriod",
          args: [BigInt(currentPeriod)],
        });

      await writeTxn(makeSetCurrentPeriodWithParams);

      setCurrentPeriod("");

      onRefetch();
    } catch (error) {
      console.error("Error handleCurrentPeriod:", error);
    }
  };

  return (
    <>
      <ActionCard>
        <h2 className="text-xl font-bold mb-4">Operation</h2>
        <Input
          type="number"
          value={currentPeriod}
          placeholder="Enter Time Period"
          onChangeHandler={value => setCurrentPeriod(value)}
        />
        <Button text="Set CurrentPeriod" bgColor="blue" onClickHandler={handleCurrentPeriod} />
      </ActionCard>
    </>
  );
};

export default SetCurrentPeriod;
