"use client";

import { useEffect, useState } from "react";
import { ethers } from "ethers";
import type { NextPage } from "next";
import { useTheme } from "next-themes";
import ActionCard from "~~/components/general/ActionCard";
import Button from "~~/components/general/Button";
import ContractValueBadge from "~~/components/general/ContractValueBadge";
import Input from "~~/components/general/Input";
import LoadingSpinner from "~~/components/general/LoadingSpinner";
import { useFetchAdminData } from "~~/hooks/custom/useFetchAdminData";
import { useFetchContractData } from "~~/hooks/custom/useFetchContractData";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";
import { ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";
import { formatAddress } from "~~/utils/vault/general";

const contractsData = getAllContracts();

const HelpersInterface: NextPage = () => {
  const { resolvedTheme } = useTheme();

  const [mounted, setMounted] = useState(false);
  const [refetch, setRefetch] = useState(false);

  const [grantRoleTrxLoading, setGrantRoleTrxLoading] = useState(false);
  const [revokeRoleTrxLoading, setRevokeRoleTrxLoading] = useState(false);
  const [periodTrxLoading, setPeriodTrxLoading] = useState(false);
  const [withdrawTrxLoading, setWithdrawTrxLoading] = useState(false);

  const [userAccountToGrant, setUserAccountToGrant] = useState("");
  const [userAccountToRevoke, setUserAccountToRevoke] = useState("");
  const [numOfPeriods, setNumOfPeriods] = useState("");
  const [assets, setAssets] = useState("");

  const contractNames = Object.keys(contractsData) as ContractName[];
  const { data: simpleUsdcContractData } = useDeployedContractInfo(contractNames[0]);

  const { data: implementationContractData, isLoading: implementationContractLoading } = useDeployedContractInfo(
    contractNames[3],
  );
  const { data: proxyContractData, isLoading: proxyContractLoading } = useDeployedContractInfo(contractNames[4]);

  const adminPrivateKey = process.env.NEXT_PUBLIC_ADMIN_PRIVATE_KEY || "";
  const adminAccount = process.env.NEXT_PUBLIC_ADMIN_ACCOUNT || "";
  const operatorPrivateKey = process.env.NEXT_PUBLIC_OPERATOR_PRIVATE_KEY || "";
  const custodian = process.env.NEXT_PUBLIC_CUSTODIAN || "";

  const provider = new ethers.JsonRpcProvider("http://localhost:8545");
  const adminSigner = new ethers.Wallet(adminPrivateKey, provider);
  const operatorSigner = new ethers.Wallet(operatorPrivateKey, provider);

  const { currentPeriod } = useFetchContractData({
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    simpleUsdcContractData,
    dependencies: [refetch],
  });

  const {
    vaultBalance,
    custodianBalance,
    adminRoleCount,
    adminRoleMembers,
    operatorRoleCount,
    operatorRoleMembers,
    upgraderRoleCount,
    upgraderRoleMembers,
    fetchingAdmins,
    fetchingOperators,
    fetchingUpgraders,
  } = useFetchAdminData({
    custodian: custodian,
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    simpleUsdcContractData: simpleUsdcContractData,
    dependencies: [refetch],
  });

  useEffect(() => {
    setMounted(true);
  }, []);

  const handleGrantRole = async (roleIndex: number) => {
    if (!userAccountToGrant || !adminSigner) {
      notification.error("Missing required fields");
      return;
    }

    try {
      setGrantRoleTrxLoading(true);

      const deployedContract = new ethers.Contract(
        proxyContractData?.address || "",
        implementationContractData?.abi || [],
        adminSigner,
      );

      let role;
      switch (roleIndex) {
        case 0:
          role = await deployedContract?.OPERATOR_ROLE();
          break;
        case 1:
          role = await deployedContract?.UPGRADER_ROLE();
          break;
        default:
          role = await deployedContract?.OPERATOR_ROLE();
          break;
      }
      const tx = await deployedContract?.grantRole(role, userAccountToGrant);
      notification.info(`Transaction submitted`);
      const receipt = await tx.wait();
      if (receipt) {
        notification.success("Transaction confirmed");
        setGrantRoleTrxLoading(false);
      }
      setUserAccountToGrant("");
      setRefetch(prev => !prev);
      setUserAccountToGrant("");
    } catch (error) {
      notification.error(`Error: ${error}`);
      setGrantRoleTrxLoading(false);
    }
  };

  const handleRevokeRole = async (roleIndex: number) => {
    if (!userAccountToRevoke || !adminSigner) {
      notification.error("Missing required fields");
      return;
    }

    try {
      setRevokeRoleTrxLoading(true);

      const deployedContract = new ethers.Contract(
        proxyContractData?.address || "",
        implementationContractData?.abi || [],
        adminSigner,
      );

      let role;
      switch (roleIndex) {
        case 0:
          role = await deployedContract?.OPERATOR_ROLE();
          break;
        case 1:
          role = await deployedContract?.UPGRADER_ROLE();
          break;
        default:
          role = await deployedContract?.OPERATOR_ROLE();
          break;
      }

      const tx = await deployedContract?.revokeRole(role, userAccountToRevoke);
      notification.info(`Transaction submitted`);
      const receipt = await tx.wait();
      if (receipt) {
        notification.success("Transaction confirmed");
        setRevokeRoleTrxLoading(false);
      }
      setUserAccountToRevoke("");
      setRefetch(prev => !prev);
      setUserAccountToRevoke("");
    } catch (error) {
      notification.error(`Error: ${error}`);
      setRevokeRoleTrxLoading(false);
    }
  };

  const handleSetPeriod = async (directionIndex: number) => {
    if (!numOfPeriods || !adminAccount || !operatorSigner) {
      notification.error("Missing required fields");
      return;
    }

    try {
      setPeriodTrxLoading(true);
      const deployedContract = new ethers.Contract(
        proxyContractData?.address || "",
        implementationContractData?.abi || [],
        operatorSigner,
      );

      const startTime: bigint = await deployedContract?._vaultStartTimestamp();
      let updatedTime;
      const secondsInADay = BigInt(86400);
      switch (directionIndex) {
        case 0: // Going backward
          updatedTime = startTime + BigInt(numOfPeriods) * secondsInADay;
          const currentTimeStamp = Math.floor(Date.now() / 1000);

          if (updatedTime > currentTimeStamp) {
            notification.error("Cannot move backward beyond the vault's start time.");
            setPeriodTrxLoading(false);
            return;
          }
          break;
        case 1: // Going forward
          updatedTime = startTime - BigInt(numOfPeriods) * secondsInADay;
          break;
        default:
          updatedTime = startTime + BigInt(numOfPeriods) * secondsInADay;
          break;
      }

      const tx = await deployedContract?.setVaultStartTimestamp(updatedTime);
      notification.info(`Transaction submitted`);
      const receipt = await tx.wait();
      if (receipt) {
        notification.success("Transaction confirmed");
        setPeriodTrxLoading(false);
      }

      setNumOfPeriods("");
      setRefetch(prev => !prev);
    } catch (error) {
      notification.error(`Error: ${error}`);
      setPeriodTrxLoading(false);
    }
  };

  const handleWithdraw = async (withdrawType: number) => {
    if (!custodian || !proxyContractData || !simpleUsdcContractData || !operatorSigner) {
      notification.error("Missing required fields");
      return;
    }

    if (!withdrawType && !assets) {
      notification.error("Missing required fields");
      return;
    }

    try {
      setWithdrawTrxLoading(true);

      const deployedContract = new ethers.Contract(
        proxyContractData?.address || "",
        implementationContractData?.abi || [],
        operatorSigner,
      );

      const simpleUsdcContract = new ethers.Contract(
        simpleUsdcContractData?.address || "",
        simpleUsdcContractData?.abi || [],
        operatorSigner,
      );

      const vaultBalance = await simpleUsdcContract.balanceOf(proxyContractData?.address);
      if (!vaultBalance) {
        notification.error("No assets to withdraw");
        return;
      }

      const custodianBalance = await simpleUsdcContract.balanceOf(custodian);

      const amountToWithdraw = !withdrawType ? ethers.parseUnits(assets?.toString(), 6) : vaultBalance;

      if (vaultBalance < amountToWithdraw) {
        notification.error("Insufficient assets to withdraw");
        return;
      }

      const tx = await deployedContract?.withdrawAsset(custodian, amountToWithdraw);
      notification.info(`Transaction submitted`);

      const receipt = await tx.wait();
      if (receipt) {
        notification.success("Transaction confirmed");
        setWithdrawTrxLoading(false);
      }

      setAssets("");
      setRefetch(prev => !prev);
    } catch (error) {
      notification.error(`Error: ${error}`);
      setWithdrawTrxLoading(false);
    }
  };

  if (!mounted) {
    return <LoadingSpinner />;
  }

  return (
    <>
      <div className="main-container mt-8 p-2">
        <div className={`container mx-auto p-6 ${resolvedTheme === "dark" ? "text-white" : "text-black"}`}>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
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
                      onClickHandler={() => handleGrantRole(0)}
                    />
                    <Button
                      text="Upgrader"
                      bgColor="blue"
                      tooltipData="Grant upgrader role"
                      flex="flex-1"
                      onClickHandler={() => handleGrantRole(1)}
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
                      onClickHandler={() => handleRevokeRole(0)}
                    />
                    <Button
                      text="Upgrader"
                      bgColor="blue"
                      tooltipData="Revoke upgrader role"
                      flex="flex-1"
                      onClickHandler={() => handleRevokeRole(1)}
                    />
                  </>
                )}
              </div>
            </ActionCard>
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
                      onClickHandler={() => handleSetPeriod(0)}
                    />
                    <Button
                      text="Go Forward"
                      bgColor="blue"
                      tooltipData="Go forward by a number of periods"
                      flex="flex-1"
                      onClickHandler={() => handleSetPeriod(1)}
                    />
                  </>
                )}
              </div>
            </ActionCard>
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
                      onClickHandler={() => handleWithdraw(0)}
                    />
                    <Button
                      text="Withdraw All"
                      bgColor="blue"
                      tooltipData="Withdraw all assets"
                      flex="flex-1"
                      onClickHandler={() => handleWithdraw(1)}
                    />
                  </>
                )}
              </div>
            </ActionCard>
          </div>

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
                <ContractValueBadge name="Vault Balance" value={`${vaultBalance} USDC`} />
              </small>
              &nbsp;&nbsp;
              <small>
                <ContractValueBadge name="Custodian Balance" value={`${custodianBalance} USDC`} />
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
                            <li key={index} className="text-gray-700">
                              {formatAddress(member)}
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
                            <li key={index} className="text-gray-700">
                              {formatAddress(member)}
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
                            <li key={index} className="text-gray-700">
                              {formatAddress(member)}
                            </li>
                          ))
                        ) : (
                          <p className="text-gray-500">No Upgraders found.</p>
                        )}
                      </ul>
                    )}
                  </div>
                </div>

                <div className="flex flex-wrap gap-4">
                  {/* <ContractValueBadge name="Current Period" value={currentPeriod} />
                  <ContractValueBadge name="Asset Amount" value={`${assetAmount} USDC`} />
                  <ContractValueBadge name="Start Time" value={startTime} />
                  <ContractValueBadge
                    name="Notice Period"
                    value={`${noticePeriod} ${noticePeriod > 1 ? "days" : "day"}`}
                  />
                  <ContractValueBadge name="Frequency" value={`${frequency} days`} />
                  <ContractValueBadge name="Tenor" value={`${tenor} days`} />
                  <ContractValueBadge name="Full Rate" value={`${fullRate}%`} />
                  <ContractValueBadge name="Reduced Rate" value={`${reducedRate}%`} /> */}
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </>
  );
};

export default HelpersInterface;
