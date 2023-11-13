import { Abi, AbiFunction } from "abitype";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { MetaHeader } from "~~/components/MetaHeader";
import { Spinner } from "~~/components/assets/Spinner";
import { ReadOnlyFunctionForm, WriteOnlyFunctionForm, getFunctionInputKey } from "~~/components/scaffold-eth";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";

const Debug: NextPage = () => {
  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo("MockStablecoin");
  const { data: deployedStable, isLoading: isLoadingStable } = useDeployedContractInfo("MockStablecoin");
  const { data: deployedSVault, isLoading: isLoadingVault } = useDeployedContractInfo("CredbullVault");
  const { address } = useAccount();

  if (
    deployedContractLoading ||
    !deployedContractData ||
    isLoadingStable ||
    !deployedStable ||
    isLoadingVault ||
    !deployedSVault ||
    !address
  ) {
    return (
      <div className="mt-14">
        <Spinner width="50px" height="50px" />
      </div>
    );
  }

  const give = (deployedContractData.abi as Abi).find(
    part => part.type === "function" && part.name === "give",
  ) as AbiFunction;

  const approve = (deployedStable.abi as Abi).find(
    part => part.type === "function" && part.name === "approve",
  ) as AbiFunction;

  const deposit = (deployedSVault.abi as Abi).find(
    part => part.type === "function" && part.name === "deposit",
  ) as AbiFunction;

  const balanceOf = (deployedSVault.abi as Abi).find(
    part => part.type === "function" && part.name === "balanceOf",
  ) as AbiFunction;

  return (
    <>
      <MetaHeader
        title="Debug Contracts | Scaffold-ETH 2"
        description="Debug your deployed 🏗 Scaffold-ETH 2 contracts in an easy way"
      />
      <div className="flex flex-col gap-y-6 lg:gap-y-8 py-8 lg:py-12 justify-center items-center">
        <div className="z-10">
          <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative w-[40rem] m-auto">
            <div className="h-[5rem] w-[13rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
              <div className="flex items-center justify-center space-x-2">
                <p className="my-0 text-sm">Vault Deposit Flow</p>
              </div>
            </div>
            <div className="p-5 divide-y divide-base-300">
              <WriteOnlyFunctionForm
                abiFunction={give}
                onChange={() => ({})}
                contractAddress={deployedContractData.address}
              />

              <WriteOnlyFunctionForm
                abiFunction={approve}
                onChange={() => ({})}
                contractAddress={deployedStable.address}
                inputs={{
                  [getFunctionInputKey(approve.name, approve.inputs[0], 0)]: deployedSVault.address,
                }}
              />
              <WriteOnlyFunctionForm
                abiFunction={deposit}
                onChange={() => ({})}
                contractAddress={deployedSVault.address}
                inputs={{
                  [getFunctionInputKey(deposit.name, deposit.inputs[1], 1)]: address,
                }}
              />
              <ReadOnlyFunctionForm
                abiFunction={balanceOf}
                contractAddress={deployedSVault.address}
                inputs={{
                  [getFunctionInputKey(balanceOf.name, balanceOf.inputs[0], 0)]: address,
                }}
              />
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Debug;
