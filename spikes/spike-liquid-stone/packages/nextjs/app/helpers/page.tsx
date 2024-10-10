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
  const [withdrawTrxLoading, setWithdrawTrxLoading] = useState(false);

  const [userAccount, setUserAccount] = useState("");
  const [numOfPeriods, setNumOfPeriods] = useState("");
  const [funds, setFunds] = useState("");

  //   const [simpleUsdcContract, setSimpleUsdcContract] = useState<ethers.Contract>();

  const contractNames = Object.keys(contractsData) as ContractName[];
  const { data: simpleUsdcContractData } = useDeployedContractInfo(contractNames[0]);

  const { data: implementationContractData } = useDeployedContractInfo(contractNames[3]);
  const { data: proxyContractData } = useDeployedContractInfo(contractNames[4]);

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

  //   useEffect(() => {
  //     if (!simpleUsdcContractData || !adminSigner) return;

  //     const _simpleUsdcContract = new ethers.Contract(
  //       simpleUsdcContractData?.address || "",
  //       simpleUsdcContractData?.abi || [],
  //       adminSigner,
  //     );

  //     setSimpleUsdcContract(_simpleUsdcContract);
  //   }, []);

  useEffect(() => {
    setMounted(true);
  }, []);

  const handleGrantRole = async (roleIndex: number) => {
    if (!userAccount || !adminSigner) {
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
      const tx = await deployedContract?.grantRole(role, userAccount);
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
    if (true) {
      notification.info("Coming soon.. A new function must be added");
      return;
    }

    // if (!custodian || !proxyContractData || !simpleUsdcContract) {
    //   notification.error("Missing required fields");
    //   return;
    // }

    // if (!withdrawType && !funds) {
    //   notification.error("Missing required fields");
    //   return;
    // }

    // try {
    //   const vaultBalance = await simpleUsdcContract.balanceOf(proxyContractData?.address);
    //   if (!vaultBalance) {
    //     notification.error("No funds to withdraw");
    //     return;
    //   }

    //   const amountToWithdraw = !withdrawType ? ethers.parseUnits(funds?.toString(), 6) : vaultBalance;

    //   if (vaultBalance < amountToWithdraw) {
    //     notification.error("Insufficient funds to withdraw");
    //     return;
    //   }

    //   setWithdrawTrxLoading(true);

    //   const tx = await deployedContract?.transferFunds(custodian, amountToWithdraw); // A new functionality needed to be added to our implementation
    //   notification.info(`Transaction submitted`);

    //   const receipt = await tx.wait();
    //   if (receipt) {
    //     notification.success("Transaction confirmed");
    //     setWithdrawTrxLoading(false);
    //   }

    //   setFunds("");
    //   setRefetch(prev => !prev);
    // } catch (error) {
    //   notification.error(`Error: ${error}`);
    //   console.log(error);
    //   setWithdrawTrxLoading(false);
    // }
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
                value={funds}
                placeholder="Enter Amount Of Funds"
                onChangeHandler={value => setFunds(value)}
              />

              <div className="flex flex-row gap-2 justify-between">
                {withdrawTrxLoading ? (
                  <LoadingSpinner />
                ) : (
                  <>
                    <Button
                      text="Withdraw"
                      bgColor="blue"
                      tooltipData="Withdraw the amount of funds you entered"
                      flex="flex-1"
                      onClickHandler={() => handleWithdraw(0)}
                    />
                    <Button
                      text="Withdraw All"
                      bgColor="blue"
                      tooltipData="Withdraw all funds"
                      flex="flex-1"
                      onClickHandler={() => handleWithdraw(1)}
                    />
                  </>
                )}
              </div>
            </ActionCard>
          </div>
        </div>
      </div>
    </>
  );
};

export default HelpersInterface;
