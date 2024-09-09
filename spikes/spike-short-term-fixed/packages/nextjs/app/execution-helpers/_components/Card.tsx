"use client";

import { useState } from "react";
import { useTheme } from "next-themes";
import { Tooltip } from "react-tooltip";
import { useWriteContract } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const contractsData = getAllContracts();
const contractNames = Object.keys(contractsData) as ContractName[];

const Card = () => {
  const [debugTimeElapsedValue, setDebugTimeElapsedValue] = useState("");
  const [refresh, setRefresh] = useState(false);
  const { targetNetwork } = useTargetNetwork();
  const writeTxn = useTransactor();
  const { data: deployedContractDataUSDC, isLoading: deployedContractLoadingUSDC } = useDeployedContractInfo(
    contractNames[0],
  );
  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractNames[1]);
  const { writeContractAsync } = useWriteContract();
  const { resolvedTheme } = useTheme();

  const refill = () => {
    if (deployedContractDataUSDC && deployedContractData) {
      if (writeContractAsync) {
        try {
          const makeWriteWithParams = () =>
            writeContractAsync({
              address: deployedContractDataUSDC.address,
              functionName: "mint",
              abi: deployedContractDataUSDC.abi,
              args: [deployedContractData.address as string, BigInt(100_000_000)],
            });
          writeTxn(makeWriteWithParams).then(data => {
            console.log("setting refresh", data);
            setRefresh(!refresh);
          });
        } catch (e: any) {
          console.error("⚡️ ~ file: WriteOnlyFunctionForm.tsx:redeem  ~ error", e);
        }
      }
    }
  };

  const handleSetTime = () => {
    if (deployedContractData) {
      if (writeContractAsync) {
        try {
          const makeWriteWithParams = () =>
            writeContractAsync({
              address: deployedContractData.address,
              functionName: "setCurrentTimePeriodsElapsed",
              abi: deployedContractData.abi,
              args: [BigInt(debugTimeElapsedValue)],
            });
          writeTxn(makeWriteWithParams).then(data => {
            console.log("setting refresh", data);
            setRefresh(!refresh);
          });
        } catch (e: any) {
          console.error("⚡️ ~ file: WriteOnlyFunctionForm.tsx:redeem  ~ error", e);
        }
      }
    }
  };

  if (deployedContractLoading || deployedContractLoadingUSDC) {
    return (
      <div className="mt-14">
        <span className="loading loading-spinner loading-lg"></span>
      </div>
    );
  }

  if (!deployedContractData || !deployedContractDataUSDC) {
    return (
      <p className="text-3xl mt-14">
        {`No contract found by the name of "${contractNames[1]}" or "${contractNames[0]}" on chain "${targetNetwork.name}"!`}
      </p>
    );
  }

  return (
    <div
      className={`container max-w-full border-2 rounded ${
        resolvedTheme === "dark" ? "border-neutral-100" : "border-black-100"
      } p-10`}
    >
      <div className="debug-section mt-6">
        <h3>Set time elapsed</h3>
        <input
          type="text"
          value={debugTimeElapsedValue}
          onChange={e => setDebugTimeElapsedValue(e.target.value)}
          placeholder="Set time elapsed"
          style={{ padding: "10px", width: "40%" }}
          onFocus={e =>
            e.target.addEventListener(
              "wheel",
              function (e) {
                e.preventDefault();
              },
              { passive: false },
            )
          }
        />

        <div className="buttons-section mt-5">
          <button
            onClick={handleSetTime}
            className={`p-2 border rounded ${
              resolvedTheme === "dark" ? "border-neutral-100" : "border-black-100"
            } min-w-32 mr-4`}
          >
            Set
          </button>
          <button
            data-tooltip-id={"refill-tooltip"}
            data-tooltip-content={"Sending interest amount to the vault"}
            data-tooltip-place={"right"}
            onClick={refill}
            className={`p-2 border rounded ${
              resolvedTheme === "dark" ? "border-neutral-100" : "border-black-100"
            } min-w-32 mr-4`}
          >
            Refill
          </button>
        </div>
      </div>
      <Tooltip id="refill-tooltip" />
    </div>
  );
};

export default Card;
