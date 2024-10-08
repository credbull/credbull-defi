"use client";

import { useEffect, useState } from "react";
import { OwnedNft } from "alchemy-sdk";
import { ethers } from "ethers";
import { useTheme } from "next-themes";
import { useChainId, useReadContract, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { Contract, ContractName } from "~~/utils/scaffold-eth/contract";
import { formatTimestamp } from "~~/utils/vault/general";
import { getNFTsForOwner } from "~~/utils/vault/web3";

type PeriodRate = {
  interestRate: number;
  effectiveFromPeriod: number;
};

const ViewSection = ({
  address,
  contractName,
  deployedContractDataUSDC,
  deployedContractLoadingUSDC,
}: {
  address: string | undefined;
  contractName: ContractName;
  deployedContractDataUSDC: Contract<ContractName> | undefined;
  deployedContractLoadingUSDC: boolean;
}) => {
  const chainId = useChainId();

  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [refetch, setRefetch] = useState(false);

  const [userDepositIds, setUserDepositIds] = useState<OwnedNft[]>([]);
  const [pools, setPools] = useState<
    { depositId: OwnedNft; balance: string; shares: string; unlockRequestAmount: string; yield: string }[]
  >([]);

  const [currentPeriod, setCurrentPeriod] = useState(0);
  const [assetAmount, setAssetAmount] = useState("");
  const [startTime, setStartTime] = useState("");
  const [noticePeriod, setNoticePeriod] = useState(0);
  const [frequency, setFrequency] = useState(0);
  const [tenor, setTenor] = useState(0);
  const [scale, setScale] = useState(0);
  const [fullRate, setFullRate] = useState(0);
  const [reducedRate, setReducedRate] = useState(0);

  const [sellAmount, setSellAmount] = useState("");
  const [currencyTokenAmount, setCurrencyTokenAmount] = useState("");
  const [requestId, setRequestId] = useState("");
  const [componentTokenAmount, setComponentTokenAmount] = useState("");
  const [currencyTokenAmountToSell, setCurrencyTokenAmountToSell] = useState("");
  const [log, setLog] = useState([]);

  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractName);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    async function fetchUserDepositIds() {
      const _userDepositIds = await getNFTsForOwner(chainId, address || "", deployedContractData?.address || "");
      if (_userDepositIds?.length > 0) {
        setUserDepositIds(_userDepositIds as OwnedNft[]);
      }
    }

    fetchUserDepositIds();
  }, [address, chainId, deployedContractData?.address]);

  useEffect(() => {
    async function fetchBalances() {
      if (!deployedContractData || !address) return;

      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
      const contract = new ethers.Contract(deployedContractData?.address, deployedContractData?.abi, provider);

      const balancePromises = userDepositIds.map(async depositId => {
        try {
          const balanceBigInt = await contract.balanceOf(address, depositId);
          const balance = ethers.formatUnits(balanceBigInt, 6);

          const sharesBigInt = await contract.sharesAtPeriod(address, depositId);
          const shares = ethers.formatUnits(sharesBigInt, 6);

          const unlockRequestAmountBigInt = await contract.unlockRequestAmountByDepositPeriod(
            address,
            Number(depositId),
          );
          const unlockRequestAmount = ethers.formatUnits(unlockRequestAmountBigInt, 6);

          if (balanceBigInt > 0) {
            const yieldAmount =
              currentPeriod > Number(depositId) ? await contract.calcYield(balanceBigInt, depositId, currentPeriod) : 0;

            return {
              depositId,
              balance,
              shares,
              unlockRequestAmount,
              yield: yieldAmount > 0 ? ethers.formatUnits(yieldAmount, 6) : yieldAmount,
            };
          }

          return null;
        } catch (error) {
          console.error("Error fetching balance for depositId:", depositId.tokenId, error);
          return null;
        }
      });

      const results = await Promise.all(balancePromises);
      const validPools = results.filter(pool => pool !== null) as {
        depositId: OwnedNft;
        balance: string;
        shares: string;
        unlockRequestAmount: string;
        yield: string;
      }[];

      setPools(validPools);
    }

    if (userDepositIds.length > 0 && deployedContractData) {
      fetchBalances();
    }
  }, [refetch, userDepositIds, deployedContractData, address, currentPeriod]);

  const { refetch: refetchCurrentPeriod } = useReadContract({
    address: deployedContractData?.address,
    functionName: "currentPeriodsElapsed",
    abi: deployedContractData?.abi,
    args: [],
  });

  const { refetch: refetchAssetAmount } = useReadContract({
    address: deployedContractDataUSDC?.address,
    functionName: "balanceOf",
    abi: deployedContractDataUSDC?.abi,
    args: [deployedContractData?.address],
  });

  const { refetch: refetchStartTime } = useReadContract({
    address: deployedContractData?.address,
    functionName: "_vaultStartTimestamp",
    abi: deployedContractData?.abi,
    args: [],
  });

  const { refetch: refetchNoticePeriod } = useReadContract({
    address: deployedContractData?.address,
    functionName: "noticePeriod",
    abi: deployedContractData?.abi,
    args: [],
  });

  const { refetch: refetchFrequency } = useReadContract({
    address: deployedContractData?.address,
    functionName: "frequency",
    abi: deployedContractData?.abi,
    args: [],
  });

  const { refetch: refetchTenor } = useReadContract({
    address: deployedContractData?.address,
    functionName: "numPeriodsForFullRate",
    abi: deployedContractData?.abi,
    args: [],
  });

  const { refetch: refetchScale } = useReadContract({
    address: deployedContractData?.address,
    functionName: "scale",
    abi: deployedContractData?.abi,
    args: [],
  });

  const { refetch: refetchFullRate } = useReadContract({
    address: deployedContractData?.address,
    functionName: "rateScaled",
    abi: deployedContractData?.abi,
    args: [],
  });

  const { refetch: refetchReducedRate } = useReadContract({
    address: deployedContractData?.address,
    functionName: "currentPeriodRate",
    abi: deployedContractData?.abi,
    args: [],
  });

  useEffect(() => {
    refetchCurrentPeriod().then(data => {
      setCurrentPeriod(Number(data?.data));
    });

    refetchAssetAmount().then(data => {
      const assetAmountBigInt = BigInt(data?.data as bigint);
      setAssetAmount(ethers.formatUnits(assetAmountBigInt, 6));
    });

    refetchStartTime().then(data => {
      setStartTime(formatTimestamp(Number(data?.data)));
    });

    refetchNoticePeriod().then(data => {
      setNoticePeriod(Number(data?.data));
    });

    refetchFrequency().then(data => {
      setFrequency(Number(data?.data));
    });

    refetchTenor().then(data => {
      setTenor(Number(data?.data));
    });

    refetchScale().then(data => {
      setScale(Number(data?.data));
    });

    refetchFullRate().then(data => {
      if (scale > 0) {
        setFullRate(Number(data?.data) / scale);
      }
    });

    refetchReducedRate().then(data => {
      if (scale > 0) {
        setReducedRate(Number((data?.data as PeriodRate)?.interestRate) / scale);
      }
    });
  }, [
    refetch,
    scale,
    deployedContractData?.address,
    refetchCurrentPeriod,
    refetchAssetAmount,
    refetchStartTime,
    refetchNoticePeriod,
    refetchFrequency,
    refetchTenor,
    refetchScale,
    refetchFullRate,
    refetchReducedRate,
  ]);

  const writeTxn = useTransactor();
  const { writeContractAsync } = useWriteContract();

  const handleBuy = async () => {
    // const message = `Bought ${currencyTokenAmount} currency tokens.`;
    // setLog([...log, message]);
    if (!address || !currencyTokenAmount) {
      console.log("Missing required fields");
      return;
    }

    try {
      if (writeContractAsync) {
        try {
          const makeApproveWithParams = () =>
            writeContractAsync({
              address: deployedContractDataUSDC?.address || "",
              functionName: "approve",
              abi: deployedContractDataUSDC?.abi || [],
              args: [deployedContractData?.address || "", ethers.parseUnits(currencyTokenAmount, 6)],
            });
          writeTxn(makeApproveWithParams).then(data => {
            console.log("setting refresh", data);

            const makeExecuteBuyWithParams = () =>
              writeContractAsync({
                address: deployedContractData?.address || "",
                functionName: "executeBuy",
                abi: deployedContractData?.abi || [],
                args: [
                  address,
                  BigInt(0),
                  ethers.parseUnits(currencyTokenAmount, 6),
                  ethers.parseUnits(currencyTokenAmount, 6),
                ],
              });
            writeTxn(makeExecuteBuyWithParams).then(data => {
              console.log("setting refresh", data);
              setRefetch(prev => !prev);
            });
          });
        } catch (e: any) {
          console.error("⚡️ ~ file: WriteOnlyFunctionForm.tsx:redeem  ~ error", e);
        }
      }

      // setLog(prevLog => [...prevLog, `Bought ${currencyTokenAmount} currency tokens.`]);

      setCurrencyTokenAmount("");
    } catch (error) {
      console.error("Error executing buy:", error);
      // setLog(prevLog => [...prevLog, "Error executing buy"]);
    }
  };

  const handleRequestSell = () => {
    // const message = `Requested to sell ${sellAmount} component tokens.`;
    // setLog([...log, message]);
    if (!address || !sellAmount) {
      console.log("Missing required fields");
      return;
    }

    try {
      if (writeContractAsync) {
        try {
          const makeRequestSellWithParams = () =>
            writeContractAsync({
              address: deployedContractData?.address || "",
              functionName: "requestSell",
              abi: deployedContractData?.abi || [],
              args: [ethers.parseUnits(sellAmount, 6)],
            });
          writeTxn(makeRequestSellWithParams).then(data => {
            console.log("setting refresh", data);
            setRefetch(prev => !prev);
          });
        } catch (e: any) {
          console.error("⚡️ ~ file: WriteOnlyFunctionForm.tsx:redeem  ~ error", e);
        }
      }

      // setLog(prevLog => [...prevLog, `Bought ${currencyTokenAmount} currency tokens.`]);

      setSellAmount("");
    } catch (error) {
      console.error("Error executing buy:", error);
      // setLog(prevLog => [...prevLog, "Error executing buy"]);
    }
  };

  const handleExecuteSell = () => {
    // const message = `Executed sell of ${componentTokenAmount} component tokens for ${currencyTokenAmount} currency tokens.`;
    // setLog([...log, message]);
    if (!address || !componentTokenAmount || !currencyTokenAmountToSell) {
      console.log("Missing required fields");
      return;
    }

    try {
      if (writeContractAsync) {
        try {
          const makeRequestSellWithParams = () =>
            writeContractAsync({
              address: deployedContractData?.address || "",
              functionName: "executeSell",
              abi: deployedContractData?.abi || [],
              args: [
                address,
                BigInt(requestId),
                ethers.parseUnits(currencyTokenAmountToSell, 6),
                ethers.parseUnits(componentTokenAmount, 6),
              ],
            });
          writeTxn(makeRequestSellWithParams).then(data => {
            console.log("setting refresh", data);
            setRefetch(prev => !prev);
          });
        } catch (e: any) {
          console.error("⚡️ ~ file: WriteOnlyFunctionForm.tsx:redeem  ~ error", e);
        }
      }

      // setLog(prevLog => [...prevLog, `Bought ${currencyTokenAmount} currency tokens.`]);

      setSellAmount("");
    } catch (error) {
      console.error("Error executing buy:", error);
      // setLog(prevLog => [...prevLog, "Error executing buy"]);
    }

    setComponentTokenAmount("");
    setCurrencyTokenAmountToSell("");
  };

  if (!mounted) {
    return (
      <div className="flex justify-center items-center h-16">
        <span className="loading loading-spinner loading-lg"></span>
      </div>
    );
  }

  const setRequestAmountToSell = (pool: {
    depositId: OwnedNft;
    balance: string;
    shares: string;
    unlockRequestAmount: string;
    yield: string;
  }) => {
    setRequestId((Number(pool.depositId) + 1).toString());
    setCurrencyTokenAmountToSell(pool.unlockRequestAmount.toString());
    setComponentTokenAmount(pool.unlockRequestAmount.toString());
  };

  return (
    <div className={`container mx-auto p-6 ${resolvedTheme === "dark" ? "text-white" : "text-black"}`}>
      <div
        className={`${resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"} p-4 rounded-lg mb-6`}
      >
        <h2 className="text-xl font-bold mb-4">Contract Details</h2>
        {deployedContractLoading ? (
          <div className="flex justify-center items-center h-16">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="flex flex-wrap gap-4">
            <span
              className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
                resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
              }`}
            >
              Current Period: {currentPeriod}
              <div
                className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
                style={{
                  background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                  pointerEvents: "none",
                }}
              ></div>
            </span>

            <span
              className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
                resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
              }`}
            >
              Asset Amount: {assetAmount} USDC
              <div
                className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
                style={{
                  background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                  pointerEvents: "none",
                }}
              ></div>
            </span>

            <span
              className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
                resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
              }`}
            >
              Start Time: {startTime}
              <div
                className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
                style={{
                  background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                  pointerEvents: "none",
                }}
              ></div>
            </span>

            <span
              className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
                resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
              }`}
            >
              Notice Period: {noticePeriod} days
              <div
                className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
                style={{
                  background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                  pointerEvents: "none",
                }}
              ></div>
            </span>

            <span
              className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
                resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
              }`}
            >
              Frequency: {frequency} days
              <div
                className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
                style={{
                  background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                  pointerEvents: "none",
                }}
              ></div>
            </span>

            <span
              className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
                resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
              }`}
            >
              Tenor: {tenor} days
              <div
                className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
                style={{
                  background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                  pointerEvents: "none",
                }}
              ></div>
            </span>

            <span
              className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
                resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
              }`}
            >
              Full Rate: {fullRate}%
              <div
                className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
                style={{
                  background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                  pointerEvents: "none",
                }}
              ></div>
            </span>

            <span
              className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
                resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
              }`}
            >
              Reduced Rate: {reducedRate}%
              <div
                className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
                style={{
                  background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                  pointerEvents: "none",
                }}
              ></div>
            </span>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        {/* Pools section */}
        {pools.map((pool, index) => (
          <div
            key={index}
            onClick={() => setRequestAmountToSell(pool)}
            className={`relative cursor-pointer overflow-hidden transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out rounded-lg shadow-xl p-6 ${
              resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
            }`}
            style={{
              borderRadius: "16px", // Rounded rectangle shape
              boxShadow:
                resolvedTheme === "dark"
                  ? "0 4px 12px rgba(255, 255, 255, 0.1), 0 6px 20px rgba(255, 255, 255, 0.1)"
                  : "0 4px 12px rgba(0, 0, 0, 0.1), 0 6px 20px rgba(0, 0, 0, 0.1)",
              transformStyle: "preserve-3d",
            }}
          >
            <div className="absolute inset-0 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 opacity-30 blur-lg rounded-lg"></div>

            <p className="relative z-10 text-center">Deposit period: {Number(pool.depositId)}</p>
            <p className="relative z-10 text-center">Balance: {pool.balance} USDC</p>
            <p className="relative z-10 text-center">Shares: {pool.shares}</p>
            <p className="relative z-10 text-center">Requested Amount: {pool.unlockRequestAmount}</p>
            <p className="relative z-10 text-center">Yield: {pool.yield} USDC</p>

            <div
              className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
              style={{
                background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
                pointerEvents: "none",
              }}
            ></div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Execute Buy */}
        <div
          className={`${
            resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
          } shadow-md p-4 rounded-lg`}
        >
          <h2 className="text-xl font-bold mb-4">Buy</h2>
          <input
            type="text"
            value={currencyTokenAmount}
            onChange={e => setCurrencyTokenAmount(e.target.value)}
            placeholder="Enter Currency Token Amount"
            className={`border ${
              resolvedTheme === "dark" ? "border-gray-700 bg-gray-700 text-white" : "border-gray-300"
            } p-2 w-full mb-4 outline-none focus:ring-0`}
          />
          <button onClick={handleBuy} className="bg-blue-500 text-white px-4 py-2 rounded">
            Execute Buy
          </button>
        </div>

        {/* Request Sell */}
        <div
          className={`${
            resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
          } shadow-md p-4 rounded-lg`}
        >
          <h2 className="text-xl font-bold mb-4">Request Sell</h2>
          <input
            type="text"
            value={sellAmount}
            onChange={e => setSellAmount(e.target.value)}
            placeholder="Enter Component Token Amount"
            className={`border ${
              resolvedTheme === "dark" ? "border-gray-700 bg-gray-700 text-white" : "border-gray-300"
            } p-2 w-full mb-4 outline-none focus:ring-0`}
          />
          <button onClick={handleRequestSell} className="bg-yellow-500 text-white px-4 py-2 rounded">
            Request Sell
          </button>
        </div>

        {/* Execute Sell */}
        <div
          className={`${
            resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
          } shadow-md p-4 rounded-lg`}
        >
          <h2 className="text-xl font-bold mb-4">
            Sell (<small>Click on the desired period to sell</small>)
          </h2>
          <input
            type="text"
            value={componentTokenAmount}
            onChange={e => setComponentTokenAmount(e.target.value)}
            placeholder="Enter Component Token Amount"
            disabled
            className={`border ${
              resolvedTheme === "dark" ? "border-gray-700 bg-gray-700 text-white" : "border-gray-300"
            } p-2 w-full mb-4 outline-none focus:ring-0`}
          />
          <input
            type="text"
            value={currencyTokenAmountToSell}
            onChange={e => setCurrencyTokenAmountToSell(e.target.value)}
            placeholder="Enter Currency Token Amount"
            disabled
            className={`border ${
              resolvedTheme === "dark" ? "border-gray-700 bg-gray-700 text-white" : "border-gray-300"
            } p-2 w-full mb-4 outline-none focus:ring-0`}
          />
          <button onClick={handleExecuteSell} className="bg-green-500 text-white px-4 py-2 rounded">
            Execute Sell
          </button>
        </div>
      </div>

      {/* Activity Log */}
      {/* <div
        className={`mt-8 ${resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"} p-4 rounded-lg`}
      >
        <h2 className="text-xl font-bold mb-4">Activity Log</h2>
        <ul>
          {log.map((entry, index) => (
            <li key={index} className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} p-2 mb-2 rounded`}>
              {entry}
            </li>
          ))}
        </ul>
      </div> */}
    </div>
  );
};

export default ViewSection;
