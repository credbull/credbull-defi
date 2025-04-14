import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { useChainId, useChains } from "wagmi";
import { LockRow } from "~~/types/async";
import { MAX_PERIODS } from "~~/utils/async/config";
import { getProvider } from "~~/utils/scaffold-eth";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

export const useFetchLocks = ({
  address,
  deployedContractAddress,
  deployedContractAbi,
  refetch,
}: {
  address: string;
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  refetch: any;
}) => {
  const chains = useChains();
  const chainId = useChainId();

  const chain = chains?.filter(_chain => _chain?.id === chainId)[0];

  const userDepositPeriods = Array.from({ length: MAX_PERIODS + 1 }, (_, index) => index);

  const [lockDatas, setLockDatas] = useState<LockRow[]>([]);

  useEffect(() => {
    async function fetchBalances() {
      if (!deployedContractAddress || !address || userDepositPeriods.length === 0) return;

      const provider = await getProvider(chain);
      const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);

      const lockPromises = userDepositPeriods.map(async depositPeriod => {
        try {
          const locked = await contract.lockedAmount(address, BigInt(depositPeriod));

          const lockedAmount = BigInt(locked || 0);
          if (lockedAmount > 0) {
            const maxUnlock = await contract.maxRequestUnlock(address, BigInt(depositPeriod));
            const unlockRequest = await contract.unlockRequestAmountByDepositPeriod(address, BigInt(depositPeriod));

            const maxRequestUnlock = BigInt(maxUnlock || 0);
            const unlockRequestAmount = BigInt(unlockRequest || 0);

            return {
              depositPeriod,
              lockedAmount,
              maxRequestUnlock,
              unlockRequestAmount,
            };
          }

          return null;
        } catch (error) {
          console.error("Error fetching balance for depositPeriod:", depositPeriod, error);
          return null;
        }
      });

      const results = await Promise.all(lockPromises);
      const validLockDatas = results.filter(row => row !== null) as LockRow[];

      setLockDatas(validLockDatas);
    }

    if (userDepositPeriods.length > 0 && deployedContractAddress) {
      fetchBalances();
    }
  }, [refetch, deployedContractAddress, deployedContractAbi, address]);

  return { lockDatas };
};
