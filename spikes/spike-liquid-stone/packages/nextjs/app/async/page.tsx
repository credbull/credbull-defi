"use client";

import ViewSection from "./_components/ViewSection";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const contractsData = getAllContracts();

const AsyncInterface: NextPage = () => {
  const { address } = useAccount();
  const contractNames = Object.keys(contractsData) as ContractName[];

  const { data: implementationContractData, isLoading: implementationContractLoading } = useDeployedContractInfo(
    contractNames[6],
  );
  const { data: proxyContractData, isLoading: proxyContractLoading } = useDeployedContractInfo(contractNames[7]);

  return (
    <>
      <div className="main-container mt-8 p-2">
        <ViewSection
          address={address}
          deployedContractAddress={proxyContractData?.address || ""}
          deployedContractAbi={implementationContractData?.abi as ContractAbi}
          deployedContractLoading={implementationContractLoading && proxyContractLoading}
        />
      </div>
    </>
  );
};

export default AsyncInterface;
