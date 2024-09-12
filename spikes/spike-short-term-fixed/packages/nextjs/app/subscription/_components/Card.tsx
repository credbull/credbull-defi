"use client";

import { useEffect, useState } from "react";
import { useTheme } from "next-themes";
import { Tooltip } from "react-tooltip";
import { useAccount, useWriteContract } from "wagmi";
import { useReadContract } from "wagmi";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { fromDecimals, toDecimals } from "~~/utils/numbers";
import { Contract, ContractName } from "~~/utils/scaffold-eth/contract";

const ViewSection = (props: any) => {
  const [userData, setUserData] = useState<number>(0);
  const [timePeriodsElapsed, setTimePeriodsElapsed] = useState<bigint>(0n);
  const [interestEarned, setInterestEarned] = useState<number>(0);

  const { refresh } = props;

  const { refetch: userReserveRefetch } = useReadContract({
    address: props.data.deployedContractData.address,
    functionName: "calcTotalDeposits",
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
    functionName: "calcTotalInterest",
    abi: props.data.deployedContractData.abi,
    args: [props.data.address],
  });

  useEffect(() => {
    userReserveRefetch().then(data => {
      if (data?.data) {
        setUserData(fromDecimals(Number(data.data)));
      }
    });

    getCurrentTimePeriodsElapsedRefetch().then(data => {
      if (data?.data) {
        setTimePeriodsElapsed(data.data as bigint);
      }
    });

    getInterestEarnedRefetch().then(data => {
      if (data?.data) {
        setInterestEarned(fromDecimals(Number(data.data)));
      }
    });
  }, [getCurrentTimePeriodsElapsedRefetch, getInterestEarnedRefetch, refresh, userReserveRefetch]);

  useEffect(() => {
    if (userData === 0)
      userReserveRefetch().then(data => {
        if (data?.data) {
          setUserData(fromDecimals(Number(data.data)));
        }
      });

    if (timePeriodsElapsed === 0n) {
      getCurrentTimePeriodsElapsedRefetch().then(data => {
        if (data?.data) {
          setTimePeriodsElapsed(data.data as bigint);
        }
      });
    }

    if (interestEarned === 0) {
      getInterestEarnedRefetch().then(data => {
        if (data?.data) {
          setInterestEarned(fromDecimals(Number(data.data)));
        }
      });
    }
  }, [
    getCurrentTimePeriodsElapsedRefetch,
    getInterestEarnedRefetch,
    interestEarned,
    timePeriodsElapsed,
    userData,
    userReserveRefetch,
  ]);

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

const Card = ({
  contractName,
  deployedContractDataUSDC,
  deployedContractLoadingUSDC,
}: {
  contractName: ContractName;
  deployedContractDataUSDC: Contract<ContractName> | undefined;
  deployedContractLoadingUSDC: boolean;
}) => {
  const [amount, setAmount] = useState("");
  const tenureDuration = 30n;
  const { address } = useAccount();
  const [refresh, setRefresh] = useState(false);
  const { targetNetwork } = useTargetNetwork();
  const writeTxn = useTransactor();
  const { writeContractAsync } = useWriteContract();
  const { resolvedTheme } = useTheme();

  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractName);

  const { refetch } = useReadContract({
    address: deployedContractData?.address,
    functionName: "getCurrentTimePeriodsElapsed",
    abi: deployedContractData?.abi,
    args: [],
  });

  const handleDeposit = () => {
    if (deployedContractData) {
      const amountWithDecimal = toDecimals(Number(amount));

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
    }
  };

  const handleRedeem = async () => {
    if (deployedContractData) {
      const amountWithDecimal = toDecimals(Number(amount));
      const timePeriodsElapsedData = await refetch();

      const timePeriodsElapsed = BigInt(timePeriodsElapsedData.data as bigint);

      const redeemAt = timePeriodsElapsed;

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
    }
  };

  const multiplyBy18 = () => {
    if (amount) {
      const bigAmount = BigInt(amount);
      const multiplier = BigInt(1e18);
      const result = bigAmount * multiplier;

      setAmount(result.toString());
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
        {`No contract found by the name of "${contractName}" on chain "${targetNetwork.name}"!`}
      </p>
    );
  }

  return (
    <div
      className={`container max-w-full border-2 rounded ${
        resolvedTheme === "dark" ? "border-neutral-100" : "border-primary"
      } p-10`}
    >
      <div className="columns-2 align-items-start mt-6">
        <div className="input-section mr-12">
          <div className="align-items-start">
            <h3>
              Amount <span className="text-xs font-extralight leading-none">number</span>
            </h3>

            <div className="relative" style={{ marginBottom: "10px" }}>
              <input
                type="text"
                value={amount}
                onChange={e => setAmount(e.target.value)}
                placeholder="Enter amount"
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
                onClick={handleDeposit}
                className={`btn btn-secondary p-2 border rounded ${
                  resolvedTheme === "dark" ? "border-neutral-100" : "border-primary"
                } min-w-32 mr-4`}
              >
                Deposit
              </button>
              <button
                onClick={handleRedeem}
                className={`btn btn-secondary btn-md p-2 border rounded ${
                  resolvedTheme === "dark" ? "border-neutral-100" : "border-primary"
                } min-w-32`}
              >
                Redeem
              </button>
            </div>
          </div>
        </div>
        <div className="view-section">
          <ViewSection data={{ deployedContractData: deployedContractData, address: address }} refresh={refresh} />
        </div>
      </div>
    </div>
  );
};

export default Card;
