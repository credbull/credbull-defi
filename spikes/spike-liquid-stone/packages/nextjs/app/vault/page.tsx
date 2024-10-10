"use client";

import ViewSection from "./_components/ViewSection";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const contractsData = getAllContracts();

const VaultInterface: NextPage = () => {
  const { address } = useAccount();
  const contractNames = Object.keys(contractsData) as ContractName[];
  const { data: simpleUsdcContractData } = useDeployedContractInfo(contractNames[0]);

  const { data: implementationContractData, isLoading: implementationContractLoading } = useDeployedContractInfo(
    contractNames[3],
  );
  const { data: proxyContractData, isLoading: proxyContractLoading } = useDeployedContractInfo(contractNames[4]);

  return (
    <>
      <div className="main-container mt-8 p-2">
        <ViewSection
          address={address}
          deployedContractAddress={proxyContractData?.address || ""}
          deployedContractAbi={implementationContractData?.abi as ContractAbi}
          deployedContractLoading={implementationContractLoading && proxyContractLoading}
          simpleUsdcContractData={simpleUsdcContractData}
        />
      </div>
    </>
  );
};

export default VaultInterface;
