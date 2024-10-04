"use client";

import { useEffect, useState } from "react";
import { OwnedNft } from "alchemy-sdk";
import { ethers } from "ethers";
import { useTheme } from "next-themes";
import { useChainId, useReadContract } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { Contract, ContractName } from "~~/utils/scaffold-eth/contract";
import { formatTimestamp } from "~~/utils/vault/general";
import { formatUnits, getNFTsForOwner } from "~~/utils/vault/web3";

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

  const [userDepositIds, setUserDepositIds] = useState<OwnedNft[]>([]);
  const [pools, setPools] = useState<{ depositId: OwnedNft; balance: string; yield: string }[]>([]);

  const [sharesAmount, setSharesAmount] = useState("");
  const [assetAmount, setAssetAmount] = useState("");
  const [startTime, setStartTime] = useState("");
  const [noticePeriod, setNoticePeriod] = useState(0);
  const [frequency, setFrequency] = useState(0);
  const [tenor, setTenor] = useState(0);
  const [scale, setScale] = useState(0);
  const [fullRate, setFullRate] = useState(0);
  const [reducedRate, setReducedRate] = useState(0);

  const [buyAmount, setBuyAmount] = useState("");
  const [sellAmount, setSellAmount] = useState("");
  const [currencyTokenAmount, setCurrencyTokenAmount] = useState("");
  const [componentTokenAmount, setComponentTokenAmount] = useState("");
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
  }, []);

  useEffect(() => {
    async function fetchBalances() {
      if (!deployedContractData || !address) return;

      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
      const contract = new ethers.Contract(deployedContractData?.address, deployedContractData?.abi, provider);

      const balancePromises = userDepositIds.map(async depositId => {
        try {
          const balanceBigInt = await contract.balanceOf(address, depositId);
          const balance = formatUnits(balanceBigInt);

          if (balanceBigInt > 0) {
            const yieldAmount = (Number(balance) * 0.05).toFixed(2);
            return {
              depositId,
              balance,
              yield: yieldAmount,
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
        yield: string;
      }[];

      setPools(validPools);
    }

    if (userDepositIds.length > 0 && deployedContractData) {
      fetchBalances();
    }
  }, [userDepositIds, deployedContractData, address]);

  const { refetch: refetchSharesAmount } = useReadContract({
    address: deployedContractData?.address,
    functionName: "totalSupply",
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
    functionName: "startTimestamp",
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
    refetchSharesAmount().then(data => {
      console.log("refetchSharesAmount", data?.data);
      const sharesAmountBigInt = BigInt(data?.data as bigint);
      setSharesAmount(formatUnits(sharesAmountBigInt));
    });

    refetchAssetAmount().then(data => {
      console.log("refetchAssetAmount", data?.data);
      const assetAmountBigInt = BigInt(data?.data as bigint);
      setAssetAmount(formatUnits(assetAmountBigInt));
    });

    refetchStartTime().then(data => {
      console.log("refetchStartTime", formatTimestamp(Number(data?.data)));
      setStartTime(formatTimestamp(Number(data?.data)));
    });

    refetchNoticePeriod().then(data => {
      console.log("refetchNoticePeriod", Number(data?.data) / (60 * 60));
      setNoticePeriod(Number(data?.data) / (60 * 60));
    });

    refetchFrequency().then(data => {
      console.log("refetchFrequency", Number(data?.data));
      setFrequency(Number(data?.data));
    });

    refetchTenor().then(data => {
      console.log("refetchTenor", Number(data?.data));
      setTenor(Number(data?.data));
    });

    refetchScale().then(data => {
      console.log("refetchScale", Number(data?.data));
      setScale(Number(data?.data));
    });

    refetchFullRate().then(data => {
      console.log("refetchFullRate", Number(data?.data) / (scale * 100));
      setFullRate(Number(data?.data) / (scale * 100));
    });

    refetchReducedRate().then(data => {
      console.log("refetchReducedRate", Number((data?.data as PeriodRate)?.interestRate) / (scale * 100));
      setReducedRate(Number((data?.data as PeriodRate)?.interestRate) / (scale * 100));
    });
  }, [
    scale,
    refetchSharesAmount,
    refetchAssetAmount,
    refetchStartTime,
    refetchNoticePeriod,
    refetchFrequency,
    refetchTenor,
    refetchScale,
    refetchFullRate,
    refetchReducedRate,
  ]);

  const handleBuy = () => {
    // const message = `Bought ${currencyTokenAmount} currency tokens.`;
    // setLog([...log, message]);
    setCurrencyTokenAmount("");
  };

  const handleRequestSell = () => {
    // const message = `Requested to sell ${sellAmount} component tokens.`;
    // setLog([...log, message]);
    setSellAmount("");
  };

  const handleExecuteSell = () => {
    // const message = `Executed sell of ${componentTokenAmount} component tokens for ${currencyTokenAmount} currency tokens.`;
    // setLog([...log, message]);
    setComponentTokenAmount("");
    setCurrencyTokenAmount("");
  };

  if (!mounted) {
    return (
      <div className="flex justify-center items-center h-16">
        <span className="loading loading-spinner loading-lg"></span>
      </div>
    );
  }

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
            <span className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} px-3 py-1 rounded-full`}>
              Shares: {sharesAmount}
            </span>
            <span className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} px-3 py-1 rounded-full`}>
              Asset Amount: {assetAmount} USDC
            </span>
            <span className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} px-3 py-1 rounded-full`}>
              Start Time: {startTime}
            </span>
            <span className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} px-3 py-1 rounded-full`}>
              Notice Period: {noticePeriod} hours
            </span>
            <span className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} px-3 py-1 rounded-full`}>
              Frequency: {frequency} days
            </span>
            <span className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} px-3 py-1 rounded-full`}>
              Tenor: {tenor} days
            </span>
            <span className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} px-3 py-1 rounded-full`}>
              Full Rate: {fullRate}%
            </span>
            <span className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} px-3 py-1 rounded-full`}>
              Reduced Rate: {reducedRate}%
            </span>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        {/* Pools section */}
        {pools.map((pool, index) => (
          <div
            key={index}
            className={`relative cursor-pointer overflow-hidden transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out rounded-full shadow-xl p-6 ${
              resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
            }`}
            style={{
              borderRadius: "50% / 35%", // Oval shape
              boxShadow:
                resolvedTheme === "dark"
                  ? "0 4px 8px rgba(255, 255, 255, 0.1), 0 6px 20px rgba(255, 255, 255, 0.1)"
                  : "0 4px 8px rgba(0, 0, 0, 0.1), 0 6px 20px rgba(0, 0, 0, 0.1)",
              transformStyle: "preserve-3d",
            }}
          >
            <div className="absolute inset-0 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 opacity-30 blur-2xl rounded-full"></div>

            {/* <h2 className="relative z-10 text-xl font-bold mb-4 text-center">Pool {index + 1}</h2> */}
            <p className="relative z-10 text-center">Deposit period: {Number(pool.depositId)}</p>
            <p className="relative z-10 text-center">Balance: {pool.balance} USDC</p>
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
          <h2 className="text-xl font-bold mb-4">Execute Buy</h2>
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
          <h2 className="text-xl font-bold mb-4">Execute Sell</h2>
          <input
            type="text"
            value={componentTokenAmount}
            onChange={e => setComponentTokenAmount(e.target.value)}
            placeholder="Enter Component Token Amount"
            className={`border ${
              resolvedTheme === "dark" ? "border-gray-700 bg-gray-700 text-white" : "border-gray-300"
            } p-2 w-full mb-4 outline-none focus:ring-0`}
          />
          <input
            type="text"
            value={currencyTokenAmount}
            onChange={e => setCurrencyTokenAmount(e.target.value)}
            placeholder="Enter Currency Token Amount"
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
      <div
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
      </div>
    </div>
  );
};

export default ViewSection;
