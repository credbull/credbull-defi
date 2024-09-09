"use client";

import { useEffect, useState } from "react";
import { Tooltip } from "react-tooltip";
import { useAccount, useWriteContract } from "wagmi";
import { useReadContract } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const contractsData = getAllContracts();
const contractNames = Object.keys(contractsData) as ContractName[];

const ViewSection = (props: any) => {
  const [userData, setUserData] = useState<number>(0);
  const [timePeriodsElapsed, setTimePeriodsElapsed] = useState<bigint>(0n);
  const [interestEarned, setInterestEarned] = useState<number>(0);

  const { refresh } = props;

  const { refetch: userReserveRefetch } = useReadContract({
    address: props.data.deployedContractData.address,
    functionName: "totalUserDeposit",
    abi: props.data.deployedContractData.abi,
    args: [props.data.address],
  });

  const { refetch: getCurrentTimePeriodsElapsedRefetch } = useReadContract({
    address: props.data.deployedContractData.address,
    functionName: "getCurrentTimePeriodsElapsed",
    abi: props.data.deployedContractData.abi,
    args: [],
  });

  const { refetch: getInterestEarnedRefetch } = useReadContract({
    address: props.data.deployedContractData.address,
    functionName: "totalInterestEarned",
    abi: props.data.deployedContractData.abi,
    args: [props.data.address],
  });

  if (!refresh) {
    userReserveRefetch().then(data => {
      setUserData(Number(Number(data.data) / 10 ** 6));
    });

    getCurrentTimePeriodsElapsedRefetch().then(data => {
      setTimePeriodsElapsed(data.data as bigint);
    });

    getInterestEarnedRefetch().then(data => {
      setInterestEarned((Number(data.data) * 1000) / 10 ** 6 / 1000);
    });
  }

  useEffect(() => {
    console.log("props", props);
    console.log("refresh", props.refresh);

    if (userData === 0)
      userReserveRefetch().then(data => {
        setUserData(Number(Number(data.data) / 10 ** 6));
      });

    if (timePeriodsElapsed === 0n) {
      getCurrentTimePeriodsElapsedRefetch().then(data => {
        setTimePeriodsElapsed(data.data as bigint);
      });
    }

    if (interestEarned === 0) {
      getInterestEarnedRefetch().then(data => {
        setInterestEarned((Number(data.data) * 1000) / 10 ** 6 / 1000);
      });
    }
  }, []);

  return (
    <>
      <div className="view-section">
        <p>Contract Address: {props.data.deployedContractData.address}</p>
        <p>Time period elapsed: {timePeriodsElapsed.toString()} </p>
        <p> Principal amount: {userData.toString()} USDC</p>
        <p> Interest earned: {interestEarned.toString()} USDC</p>
      </div>
    </>
  );
};

const Card = () => {
  const [amount, setAmount] = useState("");
  const tenureDuration = 30n;
  const [debugTimeElapsedValue, setDebugTimeElapsedValue] = useState("");
  const { address } = useAccount();
  const [refresh, setRefresh] = useState(false);
  const { targetNetwork } = useTargetNetwork();
  const writeTxn = useTransactor();
  const { data: deployedContractDataUSDC, isLoading: deployedContractLoadingUSDC } = useDeployedContractInfo(
    contractNames[0],
  );
  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractNames[1]);
  const { data: result, writeContractAsync } = useWriteContract();

  console.log(contractNames);

  const { data: contractData, refetch } = useReadContract({
    address: deployedContractData?.address,
    functionName: "getCurrentTimePeriodsElapsed",
    abi: deployedContractData?.abi,
    args: [],
  });

  const handleDeposit = () => {
    if (deployedContractData) {
      const amountWithDecimal = BigInt(Number(amount) * 10 ** 6);

      if (writeContractAsync) {
        try {
          const makeWriteWithParams = () =>
            writeContractAsync({
              address: deployedContractData.address,
              functionName: "deposit",
              abi: deployedContractData.abi,
              args: [amountWithDecimal, address as string],
            });
          writeTxn(makeWriteWithParams).then(data => {
            console.log("setting refresh", data);
            setRefresh(!refresh);
          });
        } catch (e: any) {
          console.error("⚡️ ~ file: WriteOnlyFunctionForm.tsx:deposit ~ error", e);
        }
      }
      console.log("result", result);
    }
  };

  const handleRedeem = async () => {
    if (deployedContractData) {
      const amountWithDecimal = BigInt(Number(amount) * 10 ** 6);
      const timePeriodsElapsedData = await refetch();

      const timePeriodsElapsed = BigInt(timePeriodsElapsedData.data as bigint);

      const redeemAt = timePeriodsElapsed % tenureDuration;
      console.log("redeemAt", redeemAt);

      if (writeContractAsync) {
        try {
          const makeWriteWithParams = () =>
            writeContractAsync({
              address: deployedContractData.address,
              functionName: "redeemAtPeriod",
              abi: deployedContractData.abi,
              args: [amountWithDecimal, address as string, address as string, redeemAt],
            });
          writeTxn(makeWriteWithParams).then(data => {
            console.log("setting refresh", data);
            setRefresh(!refresh);
          });
        } catch (e: any) {
          console.error("⚡️ ~ file: WriteOnlyFunctionForm.tsx:redeem  ~ error", e);
        }
      }
      console.log("result", result);
    }
  };

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
      console.log("result", result);
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
      console.log("result", result);
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
    <div className="container max-w-full border-2 rounded border-neutral-100 p-10">
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
          <button onClick={handleSetTime} className="p-2 border rounded border-neutral-100 min-w-32 mr-4">
            Set
          </button>
          <button
            data-tooltip-id={"refill-tooltip"}
            data-tooltip-content={"Sending interest amount to the vault"}
            data-tooltip-place={"right"}
            onClick={refill}
            className="p-2 border rounded border-neutral-100 min-w-32 mr-4"
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
