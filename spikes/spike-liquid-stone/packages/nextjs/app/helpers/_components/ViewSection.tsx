"use client";

import { useEffect, useState } from "react";
import SectionHeader from "./SectionHeader";
import UserDataSection from "./UserDataSection";
import { ethers } from "ethers";
import { useTheme } from "next-themes";
import { waitForTransactionReceipt } from "viem/actions";
import { useAccount, useWalletClient, useWriteContract } from "wagmi";
import ActionCard from "~~/components/general/ActionCard";
import Button from "~~/components/general/Button";
import ContractValueBadge from "~~/components/general/ContractValueBadge";
import DateTimePicker from "~~/components/general/DateTimePicker";
import Input from "~~/components/general/Input";
import LoadingSpinner from "~~/components/general/LoadingSpinner";
import { useFetchAdminData } from "~~/hooks/custom/useFetchAdminData";
import { useFetchContractData } from "~~/hooks/custom/useFetchContractData";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";
import { ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";
import { formatAddress, formatNumber } from "~~/utils/vault/general";

const contractsData = getAllContracts();

const ViewSection = () => {
  const { resolvedTheme } = useTheme();
  const { data: client } = useWalletClient();
  const { address } = useAccount();

  const [mounted, setMounted] = useState(false);
  const [refetch, setRefetch] = useState(false);

  const [grantRoleTrxLoading, setGrantRoleTrxLoading] = useState(false);
  const [revokeRoleTrxLoading, setRevokeRoleTrxLoading] = useState(false);
  const [periodTrxLoading, setPeriodTrxLoading] = useState(false);
  const [timestampTrxLoading, setTimestampTrxLoading] = useState(false);
  const [reducedRateTrxLoading, setReducedRateTrxLoading] = useState(false);
  const [withdrawTrxLoading, setWithdrawTrxLoading] = useState(false);

  const [userAccountToGrant, setUserAccountToGrant] = useState("");
  const [userAccountToRevoke, setUserAccountToRevoke] = useState("");
  const [numOfPeriods, setNumOfPeriods] = useState("");
  const [assets, setAssets] = useState("");
  const [reducedRate, setReducedRate] = useState("");

  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [selectedTimestamp, setSelectedTimestamp] = useState<number | null>(null);

  const contractNames = Object.keys(contractsData) as ContractName[];
  const { data: simpleUsdcContractData } = useDeployedContractInfo(contractNames[0]);

  const { data: implementationContractData, isLoading: implementationContractLoading } = useDeployedContractInfo(
    contractNames[4],
  );
  const { data: proxyContractData, isLoading: proxyContractLoading } = useDeployedContractInfo(contractNames[5]);

  const custodian = process.env.NEXT_PUBLIC_CUSTODIAN || "";

  const { currentPeriod, startTimestamp, previousReducedRate } = useFetchContractData({
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    simpleUsdcContractData,
    dependencies: [refetch],
  });

  const {
    allDataFetched,
    vaultBalance,
    custodianBalance,
    adminRole,
    adminRoleCount,
    adminRoleMembers,
    userHasAdminRole,
    operatorRole,
    operatorRoleCount,
    operatorRoleMembers,
    userHasOperatorRole,
    upgraderRole,
    upgraderRoleCount,
    upgraderRoleMembers,
    userHasUpgraderRole,
    assetManagerRole,
    assetManagerRoleCount,
    assetManagerRoleMembers,
    userHasAssetManagerRole,
    fetchingAdmins,
    fetchingOperators,
    fetchingUpgraders,
    fetchingAssetManagers,
  } = useFetchAdminData({
    userAccount: address || "",
    custodian: custodian,
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    simpleUsdcContractData: simpleUsdcContractData,
    dependencies: [refetch],
  });

  useEffect(() => {
    setMounted(true);
  }, []);

  const writeTxn = useTransactor();
  const { writeContractAsync } = useWriteContract();

  const handleGrantRole = async (roleIndex: number) => {
    if (!userAccountToGrant) {
      notification.error(`Grant Role: Missing userAccountToGrant`);
      return;
    }

    if (adminRole === "0x" || operatorRole === "0x" || upgraderRole === "0x" || assetManagerRole === "0x") {
      notification.warning("Initializing");
      return;
    }

    if (!userHasAdminRole) {
      notification.error("Not allowed: Admin role missed");
      return;
    }

    if (writeContractAsync) {
      setGrantRoleTrxLoading(true);

      let role;
      switch (roleIndex) {
        case 0:
          role = operatorRole;
          break;
        case 1:
          role = upgraderRole;
          break;
        case 2:
          role = assetManagerRole;
          break;
        default:
          role = operatorRole;
          break;
      }

      try {
        const makeGrantRoleTrx = () =>
          writeContractAsync({
            address: proxyContractData?.address || "",
            functionName: "grantRole",
            abi: implementationContractData?.abi || [],
            args: [role?.toString() || "", userAccountToGrant],
          });

        const trx = await writeTxn(makeGrantRoleTrx);
        if (trx) {
          const transactionReceipt = await waitForTransactionReceipt(client!, { hash: trx });
          if (transactionReceipt.status === "success") {
            setRefetch(prev => !prev);
            setUserAccountToGrant("");
            setGrantRoleTrxLoading(false);
          }
        }
      } catch (error: any) {
        setGrantRoleTrxLoading(false);
        notification.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleGrantRole  ~ error", error);
      }
    }
  };

  const handleRevokeRole = async (roleIndex: number) => {
    if (!userAccountToRevoke) {
      notification.error(`Revoke Role: Missing userAccountToRevoke`);
      return;
    }

    if (adminRole === "0x" || operatorRole === "0x" || upgraderRole === "0x" || assetManagerRole === "0x") {
      notification.warning("Initializing");
      return;
    }

    if (!userHasAdminRole) {
      notification.error("Not allowed: Admin role missed");
      return;
    }

    if (writeContractAsync) {
      setRevokeRoleTrxLoading(true);

      let role;
      switch (roleIndex) {
        case 0:
          role = operatorRole;
          break;
        case 1:
          role = upgraderRole;
          break;
        case 2:
          role = assetManagerRole;
          break;
        default:
          role = operatorRole;
          break;
      }

      try {
        const makeRevokeRoleTrx = () =>
          writeContractAsync({
            address: proxyContractData?.address || "",
            functionName: "revokeRole",
            abi: implementationContractData?.abi || [],
            args: [role?.toString() || "", userAccountToRevoke],
          });

        const trx = await writeTxn(makeRevokeRoleTrx);
        if (trx) {
          const transactionReceipt = await waitForTransactionReceipt(client!, { hash: trx });
          if (transactionReceipt.status === "success") {
            setRefetch(prev => !prev);
            setUserAccountToRevoke("");
            setRevokeRoleTrxLoading(false);
          }
        }
      } catch (error: any) {
        setRevokeRoleTrxLoading(false);
        notification.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleRevokeRole  ~ error", error);
      }
    }
  };

  const handleSetPeriod = async (directionIndex: number) => {
    if (!numOfPeriods) {
      notification.error("Set Period. Missing numOfPeriods");
      return;
    }

    if (!userHasOperatorRole) {
      notification.error("Not allowed: Operator role missed");
      return;
    }

    if (writeContractAsync) {
      setPeriodTrxLoading(true);

      let updatedTime;
      const secondsInADay = BigInt(86400);
      switch (directionIndex) {
        case 0: // Going backward
          if (previousReducedRate) {
            notification.warning(
              "Sorry! Since you initiated the reduced rate with a new value, we prevented going backward in the UI so it does not fail the Yield calculation.",
            );
            setPeriodTrxLoading(false);
            return;
          }
          updatedTime = startTimestamp + BigInt(numOfPeriods) * secondsInADay;
          const currentTimeStamp = Math.floor(Date.now() / 1000);

          if (updatedTime > currentTimeStamp) {
            notification.warning("You are trying to set the current period as a negative value.");
            setPeriodTrxLoading(false);
            return;
          }
          break;
        case 1: // Going forward
          updatedTime = startTimestamp - BigInt(numOfPeriods) * secondsInADay;
          break;
        default:
          updatedTime = startTimestamp + BigInt(numOfPeriods) * secondsInADay;
          break;
      }

      try {
        const makeSetPeriodTrx = () =>
          writeContractAsync({
            address: proxyContractData?.address || "",
            functionName: "setVaultStartTimestamp",
            abi: implementationContractData?.abi || [],
            args: [updatedTime],
          });

        const trx = await writeTxn(makeSetPeriodTrx);
        if (trx) {
          const transactionReceipt = await waitForTransactionReceipt(client!, { hash: trx });
          if (transactionReceipt.status === "success") {
            setRefetch(prev => !prev);
            setNumOfPeriods("");
            setPeriodTrxLoading(false);
          }
        }
      } catch (error: any) {
        setPeriodTrxLoading(false);
        notification.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleSetPeriod  ~ error", error);
      }
    }
  };

  const handleSetTimestamp = async () => {
    if (!selectedTimestamp) {
      notification.error("Set Timestamp.  Missing selectedTimestamp");
      return;
    }

    if (!userHasOperatorRole) {
      notification.error("Not allowed: Operator role missed");
      return;
    }

    const currentTimeStamp = Math.floor(Date.now() / 1000);

    if (selectedTimestamp > currentTimeStamp) {
      notification.warning(
        "Not Allowed in the UI. If we set the time to be after the current timestamp this will result in a negative current period value.",
      );
      setTimestampTrxLoading(false);
      return;
    }

    if (selectedTimestamp > startTimestamp && previousReducedRate) {
      notification.warning(
        "Sorry! Since you initiated the reduced rate with a new value, we prevented going backward in the UI so it does not fail the Yield calculation.",
      );
      setPeriodTrxLoading(false);
      return;
    }

    if (writeContractAsync) {
      setTimestampTrxLoading(true);

      try {
        const makeSetTimestampTrx = () =>
          writeContractAsync({
            address: proxyContractData?.address || "",
            functionName: "setVaultStartTimestamp",
            abi: implementationContractData?.abi || [],
            args: [BigInt(selectedTimestamp)],
          });

        const trx = await writeTxn(makeSetTimestampTrx);
        if (trx) {
          const transactionReceipt = await waitForTransactionReceipt(client!, { hash: trx });
          if (transactionReceipt.status === "success") {
            setRefetch(prev => !prev);
            setTimestampTrxLoading(false);
          }
        }
      } catch (error: any) {
        setTimestampTrxLoading(false);
        notification.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleSetTimestamp  ~ error", error);
      }
    }
  };

  const handleSetReducedRate = async () => {
    if (!reducedRate) {
      notification.error("Set Reduced Rate. Missing reducedRate");
      return;
    }

    if (!userHasOperatorRole) {
      notification.error("Not allowed: Operator role missed");
      return;
    }

    if (writeContractAsync) {
      setReducedRateTrxLoading(true);

      try {
        const makeSetReducedRateTrx = () =>
          writeContractAsync({
            address: proxyContractData?.address || "",
            functionName: "setReducedRateAtCurrent",
            abi: implementationContractData?.abi || [],
            args: [ethers.parseUnits(reducedRate, 6)],
          });

        const trx = await writeTxn(makeSetReducedRateTrx);
        if (trx) {
          const transactionReceipt = await waitForTransactionReceipt(client!, { hash: trx });
          if (transactionReceipt.status === "success") {
            setRefetch(prev => !prev);
            setReducedRate("");
            setReducedRateTrxLoading(false);
          }
        }
      } catch (error: any) {
        setReducedRateTrxLoading(false);
        notification.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleSetReducedRate  ~ error", error);
      }
    }
  };

  const handleWithdraw = async (withdrawType: number) => {
    if (!custodian || !proxyContractData || !simpleUsdcContractData) {
      notification.error(
        `Handle Withdraw - Missing required fields.  Custodian:${custodian} , ProxyContractData: ${proxyContractData} , SimpleUsdcContractData: ${simpleUsdcContractData}`,
      );
      return;
    }

    if (!withdrawType && !assets) {
      notification.error(`Withdraw.  Missing required fields.  Withdraw Type: ${withdrawType} , assets: ${assets}`);
      return;
    }

    if (!userHasAssetManagerRole) {
      notification.error("Not allowed: Asset Manager role missed");
      return;
    }

    if (writeContractAsync) {
      setWithdrawTrxLoading(true);

      if (!vaultBalance) {
        notification.error("No assets to withdraw");
        return;
      }

      const amountToWithdraw = !withdrawType ? ethers.parseUnits(assets?.toString(), 6) : vaultBalance;
      const amountToWithdrawInt = BigInt(
        typeof amountToWithdraw === "string" ? Math.floor(Number(amountToWithdraw) * 1e6) : amountToWithdraw,
      );

      if (vaultBalance < amountToWithdraw) {
        notification.error("Insufficient assets to withdraw");
        return;
      }

      try {
        const makeWithdrawTrx = () =>
          writeContractAsync({
            address: proxyContractData?.address || "",
            functionName: "withdrawAsset",
            abi: implementationContractData?.abi || [],
            args: [custodian, BigInt(amountToWithdrawInt)],
          });

        const trx = await writeTxn(makeWithdrawTrx);
        if (trx) {
          const transactionReceipt = await waitForTransactionReceipt(client!, { hash: trx });
          if (transactionReceipt.status === "success") {
            setRefetch(prev => !prev);
            setAssets("");
            setWithdrawTrxLoading(false);
          }
        }
      } catch (error: any) {
        setWithdrawTrxLoading(false);
        notification.error("⚡️ ~ file: vault/_components/ViewSection.tsx:handleWithdraw  ~ error", error);
      }
    }
  };

  const handleCopyToClipboard = (member: string) => {
    navigator.clipboard
      .writeText(member)
      .then(() => {
        notification.info("Copied to clipboard!");
      })
      .catch(error => {
        notification.error(`Failed to copy: ${error}`);
      });
  };

  if (!mounted) {
    return <LoadingSpinner />;
  }

  return (
    <>
      <div className="main-container mt-8 p-2">
        <div className={`container mx-auto p-6 ${resolvedTheme === "dark" ? "text-white" : "text-black"}`}>
          <UserDataSection
            allDataFetched={allDataFetched}
            userHasAdminRole={userHasAdminRole}
            userHasOperatorRole={userHasOperatorRole}
            userHasUpgraderRole={userHasUpgraderRole}
            userHasAssetManagerRole={userHasAssetManagerRole}
          />
        </div>

        <div className={`container mx-auto p-6 ${resolvedTheme === "dark" ? "text-white" : "text-black"}`}>
          {/* Admin Actions */}
          <SectionHeader title="Admin Section" />
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-10">
            <ActionCard>
              <h2 className="text-xl font-bold mb-4">Grant Roles</h2>
              <Input
                type="text"
                value={userAccountToGrant}
                placeholder="Enter User Account"
                onChangeHandler={value => setUserAccountToGrant(value)}
              />
              <div className="flex flex-row gap-2 justify-between">
                {grantRoleTrxLoading ? (
                  <LoadingSpinner />
                ) : (
                  <>
                    <Button
                      text="Operator"
                      bgColor="blue"
                      tooltipData="Grant operator role"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleGrantRole(0)}
                    />
                    <Button
                      text="Upgrader"
                      bgColor="blue"
                      tooltipData="Grant upgrader role"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleGrantRole(1)}
                    />
                    <Button
                      text="Asset Manager"
                      bgColor="blue"
                      tooltipData="Grant asset manager role"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleGrantRole(2)}
                    />
                  </>
                )}
              </div>
            </ActionCard>
            <ActionCard>
              <h2 className="text-xl font-bold mb-4">Revoke Roles</h2>
              <Input
                type="text"
                value={userAccountToRevoke}
                placeholder="Enter User Account"
                onChangeHandler={value => setUserAccountToRevoke(value)}
              />
              <div className="flex flex-row gap-2 justify-between">
                {revokeRoleTrxLoading ? (
                  <LoadingSpinner />
                ) : (
                  <>
                    <Button
                      text="Operator"
                      bgColor="blue"
                      tooltipData="Revoke operator role"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleRevokeRole(0)}
                    />
                    <Button
                      text="Upgrader"
                      bgColor="blue"
                      tooltipData="Revoke upgrader role"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleRevokeRole(1)}
                    />
                    <Button
                      text="Asset Manager"
                      bgColor="blue"
                      tooltipData="Revoke asset manager role"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleRevokeRole(2)}
                    />
                  </>
                )}
              </div>
            </ActionCard>
          </div>

          {/* Operator Actions */}
          <SectionHeader title="Operator Section" />
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-10">
            <ActionCard>
              <h2 className="text-xl font-bold mb-4">Set Period</h2>
              <Input
                type="text"
                value={numOfPeriods}
                placeholder="Enter Number Of Period"
                onChangeHandler={value => setNumOfPeriods(value)}
              />

              <div className="flex flex-row gap-2 justify-between">
                {periodTrxLoading ? (
                  <LoadingSpinner />
                ) : (
                  <>
                    <Button
                      text="Go Backward"
                      bgColor="blue"
                      tooltipData="Go backwards by a number of periods"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleSetPeriod(0)}
                    />
                    <Button
                      text="Go Forward"
                      bgColor="blue"
                      tooltipData="Go forward by a number of periods"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleSetPeriod(1)}
                    />
                  </>
                )}
              </div>
            </ActionCard>
            <ActionCard>
              <h2 className="text-xl font-bold mb-4">Set Timestamp</h2>

              <DateTimePicker
                selectedDate={selectedDate}
                setSelectedDate={setSelectedDate}
                setSelectedTimestamp={setSelectedTimestamp}
                resolvedTheme={resolvedTheme || ""}
              />

              <div className="flex flex-row gap-2 justify-between">
                {timestampTrxLoading ? (
                  <LoadingSpinner />
                ) : (
                  <>
                    <Button
                      text="Set Timestamp"
                      bgColor="blue"
                      tooltipData="Set the start timestamp for the vault"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={handleSetTimestamp}
                    />
                  </>
                )}
              </div>
            </ActionCard>
            <ActionCard>
              <div className="flex justify-between mb-4">
                <h2 className="text-xl font-bold">Set Reduced Rate</h2>
              </div>
              <Input
                type="text"
                value={reducedRate}
                placeholder="Enter Reduced Rate"
                onChangeHandler={value => setReducedRate(value)}
              />

              <div className="flex flex-row gap-2 justify-between">
                {reducedRateTrxLoading ? (
                  <LoadingSpinner />
                ) : (
                  <>
                    <Button
                      text="Set Reduced Rate"
                      bgColor="blue"
                      tooltipData="Set the reduced rate for the current period"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={handleSetReducedRate}
                    />
                  </>
                )}
              </div>
            </ActionCard>
          </div>

          {/* AssetManager Actions */}
          <SectionHeader title="Asset Manager Section" />
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-10">
            <ActionCard>
              <h2 className="text-xl font-bold mb-4">Withdraw Funds</h2>
              <Input
                type="text"
                value={assets}
                placeholder="Enter Amount Of Funds"
                onChangeHandler={value => setAssets(value)}
              />

              <div className="flex flex-row gap-2 justify-between">
                {withdrawTrxLoading ? (
                  <LoadingSpinner />
                ) : (
                  <>
                    <Button
                      text="Withdraw"
                      bgColor="blue"
                      tooltipData="Withdraw the amount of assets you entered"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleWithdraw(0)}
                    />
                    <Button
                      text="Withdraw All"
                      bgColor="blue"
                      tooltipData="Withdraw all assets"
                      flex="flex-1"
                      disabled={!allDataFetched}
                      loading={!allDataFetched}
                      onClickHandler={() => handleWithdraw(1)}
                    />
                  </>
                )}
              </div>
            </ActionCard>
          </div>

          <SectionHeader title="Data Section" />
          <div
            className={`${
              resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
            } p-4 rounded-lg mt-6`}
          >
            <h2 className="text-xl font-bold mb-4">Administration Details</h2>
            <h2>
              <small>
                <ContractValueBadge name="Current Period" value={currentPeriod} />
              </small>{" "}
              &nbsp;&nbsp;
              <small>
                <ContractValueBadge name="Vault Balance" value={`${formatNumber(vaultBalance)} USDC`} />
              </small>
              &nbsp;&nbsp;
              <small>
                <ContractValueBadge name="Custodian Balance" value={`${formatNumber(custodianBalance)} USDC`} />
              </small>
            </h2>
            {implementationContractLoading || proxyContractLoading ? (
              <LoadingSpinner />
            ) : (
              <>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 p-6 rounded-lg ">
                  {/* Admins Section */}
                  <div className="flex-1 bg-green p-4 rounded-lg shadow-sm">
                    <h1 className="mb-4">
                      <span className="text-xl font-bold text-blue-600">Admins</span> &nbsp;&nbsp;{" "}
                      <small>
                        <ContractValueBadge name="Count" value={adminRoleCount} />
                      </small>
                    </h1>
                    {fetchingAdmins ? (
                      <LoadingSpinner />
                    ) : (
                      <ul className="list-disc list-inside space-y-2">
                        {adminRoleMembers.length > 0 ? (
                          adminRoleMembers.map((member, index) => (
                            <li
                              key={index}
                              className="text-gray-700 cursor-pointer"
                              onClick={() => handleCopyToClipboard(member)}
                            >
                              <p className="m-0 tooltip tooltip-bottom tooltip-accent" data-tip={`${member} (Copy)`}>
                                {formatAddress(member)}
                              </p>
                            </li>
                          ))
                        ) : (
                          <p className="text-gray-500">No Admins found.</p>
                        )}
                      </ul>
                    )}
                  </div>

                  {/* Operators Section */}
                  <div className="flex-1 bg-green p-4 rounded-lg shadow-sm">
                    <h1 className="mb-4">
                      <span className="text-xl font-bold text-blue-600">Operators</span> &nbsp;&nbsp;{" "}
                      <small>
                        <ContractValueBadge name="Count" value={operatorRoleCount} />
                      </small>
                    </h1>
                    {fetchingOperators ? (
                      <LoadingSpinner />
                    ) : (
                      <ul className="list-disc list-inside space-y-2">
                        {operatorRoleMembers.length > 0 ? (
                          operatorRoleMembers.map((member, index) => (
                            <li
                              key={index}
                              className="text-gray-700 cursor-pointer"
                              onClick={() => handleCopyToClipboard(member)}
                            >
                              <p className="m-0 tooltip tooltip-bottom tooltip-accent" data-tip={`${member} (Copy)`}>
                                {formatAddress(member)}
                              </p>
                            </li>
                          ))
                        ) : (
                          <p className="text-gray-500">No Operators found.</p>
                        )}
                      </ul>
                    )}
                  </div>

                  {/* Upgrader Section */}
                  <div className="flex-1 bg-green p-4 rounded-lg shadow-sm">
                    <h1 className="mb-4">
                      <span className="text-xl font-bold text-blue-600">Upgraders</span> &nbsp;&nbsp;{" "}
                      <small>
                        <ContractValueBadge name="Count" value={upgraderRoleCount} />
                      </small>
                    </h1>
                    {fetchingUpgraders ? (
                      <LoadingSpinner />
                    ) : (
                      <ul className="list-disc list-inside space-y-2">
                        {upgraderRoleMembers.length > 0 ? (
                          upgraderRoleMembers.map((member, index) => (
                            <li
                              key={index}
                              className="text-gray-700 cursor-pointer"
                              onClick={() => handleCopyToClipboard(member)}
                            >
                              <p className="m-0 tooltip tooltip-bottom tooltip-accent" data-tip={`${member} (Copy)`}>
                                {formatAddress(member)}
                              </p>
                            </li>
                          ))
                        ) : (
                          <p className="text-gray-500">No Upgraders found.</p>
                        )}
                      </ul>
                    )}
                  </div>

                  {/* AssetManagers Section */}
                  <div className="flex-1 bg-green p-4 rounded-lg shadow-sm">
                    <h1 className="mb-4">
                      <span className="text-xl font-bold text-blue-600">Asset Managers</span> &nbsp;&nbsp;{" "}
                      <small>
                        <ContractValueBadge name="Count" value={assetManagerRoleCount} />
                      </small>
                    </h1>
                    {fetchingAssetManagers ? (
                      <LoadingSpinner />
                    ) : (
                      <ul className="list-disc list-inside space-y-2">
                        {assetManagerRoleMembers.length > 0 ? (
                          assetManagerRoleMembers.map((member, index) => (
                            <li
                              key={index}
                              className="text-gray-700 cursor-pointer"
                              onClick={() => handleCopyToClipboard(member)}
                            >
                              <p className="m-0 tooltip tooltip-bottom tooltip-accent" data-tip={`${member} (Copy)`}>
                                {formatAddress(member)}
                              </p>
                            </li>
                          ))
                        ) : (
                          <p className="text-gray-500">No Upgraders found.</p>
                        )}
                      </ul>
                    )}
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </>
  );
};

export default ViewSection;
