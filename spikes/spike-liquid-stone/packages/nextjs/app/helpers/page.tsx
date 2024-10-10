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
import { useFetchContractData } from "~~/hooks/custom/useFetchContractData";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";
import { ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const contractsData = getAllContracts();

const HelpersInterface: NextPage = () => {
  const { resolvedTheme } = useTheme();

  const [mounted, setMounted] = useState(false);
  const [refetch, setRefetch] = useState(false);

  const [grantRoleTrxLoading, setGrantRoleTrxLoading] = useState(false);
  const [periodTrxLoading, setPeriodTrxLoading] = useState(false);

  const contractNames = Object.keys(contractsData) as ContractName[];
  const { data: simpleUsdcContractData } = useDeployedContractInfo(contractNames[0]);

  const { data: implementationContractData, isLoading: implementationContractLoading } = useDeployedContractInfo(
    contractNames[3],
  );
  const { data: proxyContractData, isLoading: proxyContractLoading } = useDeployedContractInfo(contractNames[4]);

  const adminPrivateKey = process.env.NEXT_PUBLIC_ADMIN_PRIVATE_KEY || "";
  const adminAccount = process.env.NEXT_PUBLIC_ADMIN_ACCOUNT || "";

  const provider = new ethers.JsonRpcProvider("http://localhost:8545");
  const signer = new ethers.Wallet(adminPrivateKey, provider);

  const [contract, setContract] = useState<ethers.Contract>();

  const { currentPeriod } = useFetchContractData({
    deployedContractAddress: proxyContractData?.address || "",
    deployedContractAbi: implementationContractData?.abi as ContractAbi,
    simpleUsdcContractData,
    dependencies: [refetch],
  });

  const [userAccount, setUserAccount] = useState("");
  const [numOfPeriods, setNumOfPeriods] = useState("");

  useEffect(() => {
    if (!adminPrivateKey || !proxyContractData?.address || !implementationContractData?.abi || !signer) return;

    const _contract = new ethers.Contract(
      proxyContractData?.address || "",
      implementationContractData?.abi || [],
      signer,
    );

    setContract(_contract);
  }, [adminPrivateKey, proxyContractData, implementationContractData, adminPrivateKey]);

  useEffect(() => {
    setMounted(true);
  }, []);

  const handleGrantRole = async (roleIndex: number) => {
    if (!userAccount || !contract) {
      notification.error("Missing required fields");
      return;
    }
    try {
      setGrantRoleTrxLoading(true);
      let role;
      switch (roleIndex) {
        case 0:
          role = await contract?.OPERATOR_ROLE();
          break;
        case 1:
          role = await contract?.UPGRADER_ROLE();
          break;
        default:
          role = await contract?.OPERATOR_ROLE();
          break;
      }
      const tx = await contract?.grantRole(role, userAccount);
      notification.info(`Transaction submitted`);
      const receipt = await tx.wait();
      if (receipt) {
        notification.success("Transaction confirmed");
        setGrantRoleTrxLoading(false);
      }
      setUserAccount("");
      setRefetch(prev => !prev);
      setUserAccount("");
    } catch (error) {
      notification.error(`Error: ${error}`);
      setGrantRoleTrxLoading(false);
    }
  };

  const handleSetPeriod = async (directionIndex: number) => {
    if (!numOfPeriods || !adminAccount || !contract) {
      notification.error("Missing required fields");
      return;
    }

    try {
      setPeriodTrxLoading(true);
      const operatorRole = await contract?.OPERATOR_ROLE();
      const hasOperatorRole = await contract?.hasRole(operatorRole, adminAccount);

      if (!hasOperatorRole) {
        const tx = await contract?.grantRole(operatorRole, adminAccount);
        await tx.wait();
      }

      const startTime: bigint = await contract?._vaultStartTimestamp();
      let updatedTime;
      const secondsInADay = BigInt(86400);
      switch (directionIndex) {
        case 0:
          updatedTime = startTime + BigInt(numOfPeriods) * secondsInADay;
          break;
        case 1:
          updatedTime = startTime - BigInt(numOfPeriods) * secondsInADay;
          break;
        default:
          updatedTime = startTime + BigInt(numOfPeriods) * secondsInADay;
          break;
      }
      const tx = await contract?.setVaultStartTimestamp(updatedTime);
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

  if (!mounted) {
    return <LoadingSpinner />;
  }

  return (
    <>
      <div className="main-container mt-8 p-2">
        <div className={`container mx-auto p-6 ${resolvedTheme === "dark" ? "text-white" : "text-black"}`}>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <ActionCard>
              <h2 className="text-xl font-bold mb-4">Grant Roles</h2>
              <Input
                type="text"
                value={userAccount}
                placeholder="Enter User Account"
                onChangeHandler={value => setUserAccount(value)}
              />

              {grantRoleTrxLoading ? (
                <LoadingSpinner />
              ) : (
                <>
                  <Button
                    text="Operator"
                    bgColor="blue"
                    tooltipData="Grant operator role"
                    onClickHandler={() => handleGrantRole(0)}
                  />
                  <Button
                    text="Upgrader"
                    bgColor="blue"
                    tooltipData="Grant upgrader role"
                    onClickHandler={() => handleGrantRole(1)}
                  />
                </>
              )}
            </ActionCard>
            <ActionCard>
              <h2 className="text-xl font-bold mb-4">
                Set Period{" "}
                <small>
                  <ContractValueBadge name="Current Period" value={currentPeriod} />
                </small>
              </h2>
              <Input
                type="text"
                value={numOfPeriods}
                placeholder="Enter Number Of Period"
                onChangeHandler={value => setNumOfPeriods(value)}
              />

              {periodTrxLoading ? (
                <LoadingSpinner />
              ) : (
                <>
                  <Button
                    text="Go Backward"
                    bgColor="blue"
                    tooltipData="Go backwards by a number of periods"
                    onClickHandler={() => handleSetPeriod(0)}
                  />
                  <Button
                    text="Go Forward"
                    bgColor="blue"
                    tooltipData="Go forward by a number of periods"
                    onClickHandler={() => handleSetPeriod(1)}
                  />
                </>
              )}
            </ActionCard>
          </div>
        </div>
      </div>
    </>
  );
};

export default HelpersInterface;
