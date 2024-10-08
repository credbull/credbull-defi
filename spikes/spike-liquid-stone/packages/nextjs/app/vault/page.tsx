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
  const { data, isLoading } = useDeployedContractInfo(contractNames[0]);
  contractNames.splice(0, 1);

  return (
    <>
      <div className="main-container mt-8 p-2">
        {contractNames.map((contractName: ContractName, i: number) => {
          return contractName.includes("ERC1967Proxy") ? (
            <ViewSection
              key={i}
              address={address}
              contractName={contractName}
              deployedContractDataUSDC={data}
              deployedContractLoadingUSDC={isLoading}
            />
          ) : null;
        })}
      </div>
    </>
  );
};

export default VaultInterface;
