"use client";

import ViewSection from "./_components/ViewSection";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const contractsData = getAllContracts();

const VaultInterface: NextPage = () => {
  const { address } = useAccount();
  const contractNames = Object.keys(contractsData) as ContractName[];
  console.log("contractNames ============>", contractNames);
  const { data, isLoading } = useDeployedContractInfo(contractNames[0]);
  contractNames.splice(0, 1);

  return (
    <>
      <div className="main-container mt-8 p-10">
        <h1 className="text-2xl"> Vault Interface </h1>
        {contractNames.map((contractName: ContractName, i: number) => {
          return (
            <ViewSection
              key={i}
              address={address}
              contractName={contractName}
              deployedContractDataUSDC={data}
              deployedContractLoadingUSDC={isLoading}
            />
          );
        })}
      </div>
    </>
  );
};

export default VaultInterface;
