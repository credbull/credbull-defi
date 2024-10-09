"use client";

import { useEffect, useState } from "react";
// import ActionLogSection from "./ActionLogSection";
import Button from "../../../components/general/Button";
import ContractValueBadge from "../../../components/general/ContractValueBadge";
import Input from "../../../components/general/Input";
import LoadingSpinner from "../../../components/general/LoadingSpinner";
import DepositPoolCard from "./DepositPoolCard";
import { OwnedNft } from "alchemy-sdk";
import { ethers } from "ethers";
import { useTheme } from "next-themes";
import { useChainId, useWriteContract } from "wagmi";
import ActionCard from "~~/components/general/ActionCard";
import { useFetchContractData } from "~~/hooks/custom/useFetchContractData";
import { useFetchDepositPools } from "~~/hooks/custom/useFetchDepositPools";
import { useFetchSellRequests } from "~~/hooks/custom/useFetchSellRequests";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { DepositPool, SellRequest } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";
import { Contract, ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";

const ViewSection = ({
  address,
  deployedContractAddress,
  deployedContractAbi,
  deployedContractLoading,
  simpleUsdcContractData,
}: {
  address: string | undefined;
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  deployedContractLoading: boolean;
  simpleUsdcContractData: Contract<ContractName> | undefined;
}) => {
  const chainId = useChainId();

  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [refetch, setRefetch] = useState(false);

  const [sellAmount, setSellAmount] = useState("");
  const [currencyTokenAmount, setCurrencyTokenAmount] = useState("");
  const [requestId, setRequestId] = useState("");
  const [componentTokenAmount, setComponentTokenAmount] = useState("");
  const [currencyTokenAmountToSell, setCurrencyTokenAmountToSell] = useState("");

  useEffect(() => {
    setMounted(true);
  }, []);

  const { currentPeriod, assetAmount, startTime, noticePeriod, frequency, tenor, fullRate, reducedRate } =
    useFetchContractData({
      deployedContractAddress,
      deployedContractAbi,
      simpleUsdcContractData,
      dependencies: [refetch],
    });

  const { pools } = useFetchDepositPools({
    chainId,
    address: address || "",
    deployedContractAddress,
    deployedContractAbi,
    currentPeriod,
    refetch,
  });

  const { sellRequests } = useFetchSellRequests({
    address: address || "",
    deployedContractAddress,
    deployedContractAbi,
    currentPeriod,
    refetch,
  });

  const writeTxn = useTransactor();
  const { writeContractAsync } = useWriteContract();

  const handleBuy = async () => {
    // const message = `Bought ${currencyTokenAmount} currency tokens.`;
    // setLog([...log, message]);
    if (!address || !currencyTokenAmount) {
      notification.error("Missing required fields");
      return;
    }

    try {
      if (writeContractAsync) {
        try {
          const makeApproveWithParams = () =>
            writeContractAsync({
              address: simpleUsdcContractData?.address || "",
              functionName: "approve",
              abi: simpleUsdcContractData?.abi || [],
              args: [deployedContractAddress || "", ethers.parseUnits(currencyTokenAmount, 6)],
            });
          writeTxn(makeApproveWithParams).then(data => {
            console.log("setting refresh", data);

            const makeExecuteBuyWithParams = () =>
              writeContractAsync({
                address: deployedContractAddress || "",
                functionName: "executeBuy",
                abi: deployedContractAbi || [],
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
      notification.error("Missing required fields");
      return;
    }

    try {
      if (writeContractAsync) {
        try {
          const makeRequestSellWithParams = () =>
            writeContractAsync({
              address: deployedContractAddress || "",
              functionName: "requestSell",
              abi: deployedContractAbi || [],
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
      notification.error(`Error executing buy: ${error?.toString()}`);
      // setLog(prevLog => [...prevLog, "Error executing buy"]);
    }
  };

  const handleExecuteSell = () => {
    // const message = `Executed sell of ${componentTokenAmount} component tokens for ${currencyTokenAmount} currency tokens.`;
    // setLog([...log, message]);
    if (!address || !componentTokenAmount || !currencyTokenAmountToSell) {
      notification.error("Missing required fields");
      return;
    }

    try {
      if (writeContractAsync) {
        try {
          const makeRequestSellWithParams = () =>
            writeContractAsync({
              address: deployedContractAddress || "",
              functionName: "executeSell",
              abi: deployedContractAbi || [],
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

  const setRequestAmountToSell = (request: SellRequest) => {
    const requestId = request?.id?.toString();
    const amount = request?.amount?.toString();
    setRequestId(requestId);
    setCurrencyTokenAmountToSell(amount?.toString());
    setComponentTokenAmount(amount?.toString());
  };

  if (!mounted) {
    return <LoadingSpinner />;
  }

  return (
    <div className={`container mx-auto p-6 ${resolvedTheme === "dark" ? "text-white" : "text-black"}`}>
      <div
        className={`${resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"} p-4 rounded-lg mb-6`}
      >
        <h2 className="text-xl font-bold mb-4">Contract Details</h2>
        {deployedContractLoading ? (
          <LoadingSpinner />
        ) : (
          <div className="flex flex-wrap gap-4">
            <ContractValueBadge name="Current Period" value={currentPeriod} />
            <ContractValueBadge name="Asset Amount" value={`${assetAmount} USDC`} />
            <ContractValueBadge name="Start Time" value={startTime} />
            <ContractValueBadge name="Notice Period" value={`${noticePeriod} ${noticePeriod > 1 ? "days" : "day"}`} />
            <ContractValueBadge name="Frequency" value={`${frequency} days`} />
            <ContractValueBadge name="Tenor" value={`${tenor} days`} />
            <ContractValueBadge name="Full Rate" value={`${fullRate}%`} />
            <ContractValueBadge name="Reduced Rate" value={`${reducedRate}%`} />
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div className="grid gap-3">
          {pools.map((pool, index) => (
            <DepositPoolCard key={index} pool={pool} onClickHandler={() => {}} />
          ))}
        </div>
        <div
          className={`${resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"} p-4 rounded-lg`}
        >
          <h2 className="text-xl font-bold mb-4">Requests</h2>
          {deployedContractLoading ? (
            <LoadingSpinner />
          ) : (
            <div className="flex flex-wrap gap-4">
              {sellRequests?.map((request, index) => (
                <ContractValueBadge
                  key={index}
                  name={`Request ${request?.id}`}
                  value={`${request?.amount?.toString()} USDC`}
                  onClickHandler={() => setRequestAmountToSell(request)}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Execute Buy */}
        <ActionCard>
          <h2 className="text-xl font-bold mb-4">Buy</h2>
          <Input
            type="text"
            value={currencyTokenAmount}
            placeholder="Enter Currency Token Amount"
            onChangeHandler={value => setCurrencyTokenAmount(value)}
          />

          <Button text="Execute Buy" bgColor="blue" onClickHandler={handleBuy} />
        </ActionCard>

        {/* Request Sell */}
        <ActionCard>
          <h2 className="text-xl font-bold mb-4">Request Sell</h2>
          <Input
            type="text"
            value={sellAmount}
            placeholder="Enter Component Token Amount"
            onChangeHandler={value => setSellAmount(value)}
          />

          <Button text="Request Sell" bgColor="yellow" onClickHandler={handleRequestSell} />
        </ActionCard>

        {/* Execute Sell */}
        <ActionCard>
          <h2 className="text-xl font-bold mb-4">
            Sell (<small>Click on the desired request</small>)
          </h2>
          <Input
            type="text"
            value={componentTokenAmount}
            placeholder="Enter Component Token Amount"
            disabled
            onChangeHandler={value => setComponentTokenAmount(value)}
          />
          <Input
            type="text"
            value={currencyTokenAmountToSell}
            placeholder="Enter Component Token Amount"
            disabled
            onChangeHandler={value => setCurrencyTokenAmountToSell(value)}
          />

          <Button text="Execute Sell" bgColor="green" onClickHandler={handleExecuteSell} />
        </ActionCard>
      </div>

      {/* Activity Log */}
      {/* <ActionLogSection log={log} /> */}
    </div>
  );
};

export default ViewSection;
