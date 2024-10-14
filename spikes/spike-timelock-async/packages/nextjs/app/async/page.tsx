"use client";

import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";
import { ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";

import { useFetchContractData } from "~~/hooks/custom/useFetchContractData";
import PeriodButtons from './_components/PeriodButtons';
import SetCurrentPeriod from './_components/SetCurrentPeriod';
import LockAmount from "./_components/LockAmount";
import RequestUnlock from "./_components/RequestUnlock";
import LockedAmountTable from "./_components/LockedAmountTable";
import RequestIdTable from "./_components/RequestIdTable";

const contractsData = getAllContracts();

const Async: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const contractNames = Object.keys(contractsData) as ContractName[];

  const { data: implContractData } = useDeployedContractInfo(contractNames[1]);
  const { data: proxyContractData } = useDeployedContractInfo(contractNames[2]);

  const proxyAddress = proxyContractData?.address || "";
  const implAbi = implContractData?.abi as ContractAbi;


  const { noticePeriod, currentPeriod, refetchCurrentPeriod } =
    useFetchContractData({
      deployedContractAddress: proxyAddress,
      deployedContractAbi: implAbi,
    });

  return (
    <>
      <div className="main-container mt-8 p-4">
        {/* Display the notice period */}
        <div className="">
          <h2 className="text-lg font-bold">Notice Period: {noticePeriod} Days</h2>
          <h2 className="text-lg font-bold">Current Period: {currentPeriod}</h2>
        </div>

        {/* Render SetCurrentPeriod component with proxyAddress and ABI props */}
        <SetCurrentPeriod proxyAddress={proxyAddress} abi={implAbi} refetchCurrentPeriod={refetchCurrentPeriod} />

        {/* Render period buttons */}
        <PeriodButtons />
        <div className="flex gap-8">
            <LockedAmountTable
              proxyAddress={proxyAddress}
              abi={implAbi}
              userAddress={connectedAddress || ""}
            />
            <RequestIdTable
              proxyAddress={proxyAddress}
              abi={implAbi}
              userAddress={connectedAddress || ""}
            />
        </div>
        <LockAmount
          proxyAddress={proxyAddress}
          abi={implAbi}
          userAddress={connectedAddress || ""}
        />

        <RequestUnlock
          proxyAddress={proxyAddress}
          abi={implAbi}
          userAddress={connectedAddress || ""}
        />
      </div> 
    </>
  );
};

export default Async;
