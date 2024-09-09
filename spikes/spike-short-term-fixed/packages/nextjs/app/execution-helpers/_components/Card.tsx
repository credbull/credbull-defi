"use client";

import { useState } from "react";
import { useTheme } from "next-themes";
import { Tooltip } from "react-tooltip";
import { useWriteContract } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { ContractName } from "~~/utils/scaffold-eth/contract";

const Card = ({ contractNames }: { contractNames: ContractName[] }) => {
  const [debugTimeElapsedValue, setDebugTimeElapsedValue] = useState("");
  const [refresh, setRefresh] = useState(false);
  const { targetNetwork } = useTargetNetwork();
  const writeTxn = useTransactor();
  const { writeContractAsync } = useWriteContract();
  const { resolvedTheme } = useTheme();

  const { data: deployedContractDataUSDC, isLoading: deployedContractLoadingUSDC } = useDeployedContractInfo(
    contractNames[0],
  );
  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractNames[1]);

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

  const multiplyBy18 = () => {
    if (debugTimeElapsedValue) {
      setDebugTimeElapsedValue(prev => (Number(prev) * 1e18).toString());
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
        resolvedTheme === "dark" ? "border-neutral-100" : "border-primary"
      } p-10`}
    >
      <div className="debug-section mt-6">
        <h3>
          Time elapsed <span className="text-xs font-extralight leading-none">number</span>
        </h3>

        <div className="relative w-1/2">
          <input
            type="text"
            value={debugTimeElapsedValue}
            onChange={e => setDebugTimeElapsedValue(e.target.value)}
            placeholder="Set time elapsed"
            className={`border ${
              resolvedTheme === "dark" ? "border-neutral-100" : "border-primary placeholder-primary"
            } rounded-full outline-none focus:ring-0 pr-10`}
            style={{ padding: "10px", width: "100%" }}
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

          <button
            data-tooltip-id="multiply-tooltip"
            data-tooltip-content="Multiply by 1e18 (wei)"
            className={`absolute right-2 top-1/2 transform -translate-y-1/2 text-primary rounded-full p-1 focus:outline-none`}
            style={{ height: "30px", width: "30px", backgroundColor: "transparent" }}
            onClick={multiplyBy18}
          >
            <span className={`text-2xl ${resolvedTheme === "dark" ? "text-white" : "text-primary"}`}>*</span>
          </button>

          <Tooltip id="multiply-tooltip" />
        </div>

        <div className="buttons-section mt-5">
          <button
            onClick={handleSetTime}
            className={`p-2 border rounded ${
              resolvedTheme === "dark" ? "border-neutral-100" : "border-primary"
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
              resolvedTheme === "dark" ? "border-neutral-100" : "border-primary"
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
