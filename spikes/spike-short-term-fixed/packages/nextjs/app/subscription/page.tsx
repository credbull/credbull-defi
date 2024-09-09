"use client";

import Card from "./_components/Card";
import type { NextPage } from "next";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const contractsData = getAllContracts();

const ShortTerm: NextPage = () => {
  const contractNames = Object.keys(contractsData) as ContractName[];
  const { data: deployedContractDataUSDC, isLoading: deployedContractLoadingUSDC } = useDeployedContractInfo(
    contractNames[0],
  );
  contractNames.splice(0, 1);

  return (
    <>
      <div className="main-container mt-8 p-10">
        <h1 className="text-2xl"> Short term fixed yield - 30 days </h1>
        {contractNames.map((contractName: ContractName, i: number) => {
          return (
            <Card
              key={i}
              contractName={contractName}
              deployedContractDataUSDC={deployedContractDataUSDC}
              deployedContractLoadingUSDC={deployedContractLoadingUSDC}
            />
          );
        })}
      </div>
    </>
  );
};

export default ShortTerm;
