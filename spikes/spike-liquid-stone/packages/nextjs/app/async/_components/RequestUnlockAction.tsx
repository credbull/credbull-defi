"use client";

import { useState } from "react";
import Button from "../../../components/general/Button";
import Input from "../../../components/general/Input";
import { useWriteContract } from "wagmi";
import ActionCard from "~~/components/general/ActionCard";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

const RequestUnlockAction = ({
  address,
  deployedContractAddress,
  deployedContractAbi,
  currentPeriod,
  onRefetch,
}: {
  address: string | undefined;
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  currentPeriod: number;
  onRefetch: () => void;
}) => {
  const [inputPairs, setInputPairs] = useState([{ period: "", amount: "" }]);

  const writeTxn = useTransactor();
  const { writeContractAsync } = useWriteContract();

  const handleInputChange = (index: number, field: "period" | "amount", value: string) => {
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
      if (!address) {
        notification.error("Missing required fields");
        return;
      }
      // Check first if all pair is valid
      const isValidInput = inputPairs.every(pair => pair.period.trim() !== "" && pair.amount.trim() !== "");

      if (!isValidInput) {
        notification.error("All fields must be filled.");
        return;
      }

      // Check if all pair's deposit periods are less than currentPeriod
      const isValidPeriod = inputPairs.every(pair => Number(pair.period) <= currentPeriod);
      if (!isValidPeriod) {
        notification.error(`All deposit periods must be less than or equal to ${currentPeriod}(Current Period).`);
        return;
      }

      const depositPeriodsForUnlockRequest = inputPairs.map(pair => BigInt(pair.period));
      const amountsForUnlockRequest = inputPairs.map(pair => BigInt(pair.amount));

      const makeUnlockRequestWithParams = () =>
        writeContractAsync({
          address: deployedContractAddress,
          abi: deployedContractAbi,
          functionName: "requestUnlock",
          args: [address, depositPeriodsForUnlockRequest, amountsForUnlockRequest],
        });

      await writeTxn(makeUnlockRequestWithParams);

      setInputPairs([{ period: "", amount: "" }]);

      onRefetch();
    } catch (error) {
      console.error("Error handleUnlockRequest:", error);
    }
  };

  return (
    <>
      <ActionCard>
        <h2 className="text-xl font-bold mb-4">Request Unlock</h2>
        {inputPairs.map((pair, index) => (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3" key={index}>
            <Input
              type="number"
              value={pair.period}
              placeholder="Enter Deposit Period"
              onChangeHandler={value => handleInputChange(index, "period", value)}
            />
            <Input
              type="number"
              value={pair.amount}
              placeholder="Enter Amount"
              onChangeHandler={value => handleInputChange(index, "amount", value)}
            />
          </div>
        ))}

        <div className="grid grid-cols-2 gap-3 mb-4">
          <Button text="+ Add" bgColor="green" onClickHandler={handleAddInput} />
          <Button text="- Remove" bgColor="yellow" onClickHandler={handleRemoveInput} />
        </div>

        <Button text="Request Unlock" bgColor="blue" onClickHandler={handleUnlockRequest} />
      </ActionCard>
    </>
  );
};

export default RequestUnlockAction;
