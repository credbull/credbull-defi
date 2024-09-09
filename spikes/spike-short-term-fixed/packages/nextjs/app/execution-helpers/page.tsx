import Card from "./_components/Card";
import type { NextPage } from "next";
import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";
import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

const allContractVersions = getAllContracts();

export const metadata = getMetadata({
  title: "Short term yield",
  description: "Short term yield",
});

const ShortTerm: NextPage = () => {
  return (
    <>
      <div className="main-container mt-8 p-10">
        <h1 className="text-2xl"> Execution helpers </h1>
        {allContractVersions.map((contractsData, i: number) => {
          const contractNames = Object.keys(contractsData) as ContractName[];

          return <Card key={i} contractNames={contractNames} />;
        })}
      </div>
    </>
  );
};

export default ShortTerm;
