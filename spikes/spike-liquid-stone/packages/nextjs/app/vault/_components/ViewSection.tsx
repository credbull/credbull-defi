"use client";

import { useEffect, useState } from "react";
// import ActionLogSection from "./ActionLogSection";
import Button from "../../../components/general/Button";
import ContractValueBadge from "../../../components/general/ContractValueBadge";
import Input from "../../../components/general/Input";
import LoadingSpinner from "../../../components/general/LoadingSpinner";
import DepositPoolCard from "./DepositPoolCard";
import { ethers } from "ethers";
import { useTheme } from "next-themes";
import { useAccount, useChainId, useWriteContract } from "wagmi";
import { CheckCircleIcon } from "@heroicons/react/24/solid";
import ActionCard from "~~/components/general/ActionCard";
import { useFetchContractData } from "~~/hooks/custom/useFetchContractData";
import { useFetchDepositPools } from "~~/hooks/custom/useFetchDepositPools";
import { useFetchRedeemRequests } from "~~/hooks/custom/useFetchRedeemRequests";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { RedeemRequest } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";
import { ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";
import { formatNumber } from "~~/utils/vault/general";

const contractsData = getAllContracts();

const ViewSection = () => {
  const { address } = useAccount();
  const contractNames = Object.keys(contractsData) as ContractName[];
  const { data: simpleUsdcContractData } = useDeployedContractInfo(contractNames[0]);

  const { data: implementationContractData, isLoading: implementationContractLoading } = useDeployedContractInfo(
    contractNames[3],
  );
  const { data: proxyContractData, isLoading: proxyContractLoading } = useDeployedContractInfo(contractNames[4]);

  const deployedContractAddress = proxyContractData?.address || "";
  const deployedContractAbi = implementationContractData?.abi as ContractAbi;
  const deployedContractLoading = implementationContractLoading || proxyContractLoading;

  const chainId = useChainId();

  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [refetch, setRefetch] = useState(false);

  const [sharesToRequest, setSharesToRequest] = useState("");
  const [assets, setAssets] = useState("");
  const [sharesToRedeem, setSharesToRedeem] = useState("");
  const [assetsToRedeem, setAssetsToRedeem] = useState("");

  useEffect(() => {
    setMounted(true);
  }, []);

  const {
    currentPeriod,
    assetAmount,
    startTime,
    noticePeriod,
    frequency,
    tenor,
    fullRate,
    currentReducedRate,
    previousReducedRate,
    effectiveReducedRate,
  } = useFetchContractData({
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

  const { redeemRequests } = useFetchRedeemRequests({
    address: address || "",
    deployedContractAddress,
    deployedContractAbi,
    currentPeriod,
    refetch,
  });

  const writeTxn = useTransactor();
  const { writeContractAsync } = useWriteContract();

  const handleRequestDeposit = async () => {
    // const message = `Bought ${assets} currency tokens.`;
    // setLog([...log, message]);
    if (!address || !assets) {
      notification.error("Missing required fields");
      return;
    }

    if (writeContractAsync) {
      try {
        const makeApprove = () =>
          writeContractAsync({
            address: simpleUsdcContractData?.address || "",
            functionName: "approve",
            abi: simpleUsdcContractData?.abi || [],
            args: [deployedContractAddress || "", ethers.parseUnits(assets, 6)],
          });
        writeTxn(makeApprove).then(data => {
          console.log("setting refresh", data);

          try {
            const makeRequestDeposit = () =>
              writeContractAsync({
                address: deployedContractAddress || "",
                functionName: "requestDeposit",
                abi: deployedContractAbi || [],
                args: [ethers.parseUnits(assets, 6), address, address],
              });
            writeTxn(makeRequestDeposit).then(data => {
              console.log("setting refresh", data);
              setRefetch(prev => !prev);
            });
          } catch (error) {
            console.error(
              "⚡️ ~ file: vault/_components/ViewSection.tsx:handleRequestDeposit:requestDeposit  ~ error",
              error,
            );
          }
        });
      } catch (error: any) {
        console.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleRequestDeposit:approve  ~ error", error);
      }
    }

    // setLog(prevLog => [...prevLog, `Bought ${assets} currency tokens.`]);

    setAssets("");
  };

  const handleRequestRedeem = () => {
    // const message = `Requested to redeem ${sharesToRequest} component tokens.`;
    // setLog([...log, message]);
    if (!address || !sharesToRequest) {
      notification.error("Missing required fields");
      return;
    }

    if (writeContractAsync) {
      try {
        const makeRequestRedeem = () =>
          writeContractAsync({
            address: deployedContractAddress || "",
            functionName: "requestRedeem",
            abi: deployedContractAbi || [],
            args: [ethers.parseUnits(sharesToRequest, 6), address, address],
          });
        writeTxn(makeRequestRedeem).then(data => {
          console.log("setting refresh", data);
          setRefetch(prev => !prev);
        });
      } catch (error: any) {
        console.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleRequestRedeem  ~ error", error);
      }
    }

    // setLog(prevLog => [...prevLog, `Requested to redeem ${sharesToRequest} sharesToRequest.`]);

    setSharesToRequest("");
  };

  const handleRedeem = () => {
    // const message = `Redeemed of ${sharesToRedeem} shares.`;
    // setLog([...log, message]);
    if (!address || !sharesToRedeem) {
      notification.error("Missing required fields");
      return;
    }

    if (parseFloat(assetAmount) < parseFloat(assetsToRedeem)) {
      const errorMsg = "Sorry! Not enough balance in the vault. " + assetAmount + " < " + assetsToRedeem;
      notification.error(errorMsg);
      return;
    }

    if (writeContractAsync) {
      try {
        const makeRedeem = () =>
          writeContractAsync({
            address: deployedContractAddress || "",
            functionName: "redeem",
            abi: deployedContractAbi || [],
            args: [ethers.parseUnits(sharesToRedeem, 6), address, address],
          });
        writeTxn(makeRedeem).then(data => {
          console.log("setting refresh", data);
          setRefetch(prev => !prev);
        });
      } catch (error: any) {
        console.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleRedeem  ~ error", error);
      }
    }

    // setLog(prevLog => [...prevLog, `Bought ${assets} currency tokens.`]);

    setSharesToRedeem("");
  };

  const setRequestAmountToRedeem = (request: RedeemRequest) => {
    if (request?.id !== currentPeriod) {
      notification.error(`You should redeem this request at period #${request?.id}.`);
      return;
    }

    const shareAmount = request?.shareAmount?.toString();
    const assetAmount = request?.assetAmount?.toString();
    setSharesToRedeem(shareAmount?.toString());
    setAssetsToRedeem(assetAmount?.toString());
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
            <ContractValueBadge name="Asset Amount" value={`${formatNumber(assetAmount)} USDC`} />
            <ContractValueBadge name="Start Time" value={startTime} />
            <ContractValueBadge name="Notice Period" value={`${noticePeriod} ${noticePeriod > 1 ? "days" : "day"}`} />
            <ContractValueBadge name="Frequency" value={`${frequency} days`} />
            <ContractValueBadge name="Tenor" value={`${tenor} days`} />
            <ContractValueBadge name="Full Rate" value={`${fullRate}%`} />
            <ContractValueBadge
              name="Previous Reduced Rate"
              value={`${previousReducedRate}%`}
              icon={effectiveReducedRate === "0" ? <CheckCircleIcon style={{ width: "16px", height: "16px" }} /> : ""}
            />
            <ContractValueBadge
              name="Current Reduced Rate"
              value={`${currentReducedRate}%`}
              icon={effectiveReducedRate === "1" ? <CheckCircleIcon style={{ width: "16px", height: "16px" }} /> : ""}
            />
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div
          className={`${
            resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
          } p-4 rounded-lg grid gap-3`}
        >
          <h2 className="text-xl font-bold mb-4">Deposit Pools</h2>
          {pools.map((pool, index) => (
            <DepositPoolCard key={index} pool={pool} />
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
              {redeemRequests?.map((request, index) => (
                <ContractValueBadge
                  key={index}
                  name={`Request ${request?.id}`}
                  value={
                    <>
                      shares: {formatNumber(request?.shareAmount)} - assets: {formatNumber(request?.assetAmount)} USDC
                    </>
                  }
                  onClickHandler={() => setRequestAmountToRedeem(request)}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Request Deposit */}
        <ActionCard>
          <h2 className="text-xl font-bold mb-4">Request Deposit</h2>
          <Input
            type="text"
            value={assets}
            placeholder="Enter Asset Amount"
            onChangeHandler={value => setAssets(value)}
          />

          <Button text="Request Deposit" bgColor="green" onClickHandler={handleRequestDeposit} />
        </ActionCard>

        {/* Request Redeem */}
        <ActionCard>
          <h2 className="text-xl font-bold mb-4">Request Redeem</h2>
          <Input
            type="text"
            value={sharesToRequest}
            placeholder="Enter Shares Amount"
            onChangeHandler={value => setSharesToRequest(value)}
          />

          <Button text="Request Redeem" bgColor="gray" onClickHandler={handleRequestRedeem} />
        </ActionCard>

        {/* Redeem */}
        <ActionCard>
          <h2 className="mb-4">
            <span className="text-xl font-bold ">Redeem</span> (<small>Click on the desired request</small>)
          </h2>
          <Input
            type="text"
            value={sharesToRedeem}
            placeholder="Enter Shares Amount"
            disabled
            onChangeHandler={value => setSharesToRedeem(value)}
          />

          <Button text="Redeem" bgColor="green" onClickHandler={handleRedeem} />
        </ActionCard>
      </div>

      {/* Activity Log */}
      {/* <ActionLogSection log={log} /> */}
      {/* <ActionLogSection log={log} /> */}
    </div>
  );
};

export default ViewSection;
