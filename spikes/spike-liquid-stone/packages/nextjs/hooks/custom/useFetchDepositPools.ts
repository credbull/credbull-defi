import { useEffect, useState } from "react";
import { OwnedNft } from "alchemy-sdk";
import { ethers } from "ethers";
import { DepositPool } from "~~/types/vault";
import { getNFTsForOwner } from "~~/utils/vault/web3";

export const useFetchDepositPools = ({
  chainId,
  address,
  deployedContractAddress,
  deployedContractAbi,
  currentPeriod,
  refetch,
}: {
  chainId: number;
  address: string;
  deployedContractAddress: string;
  deployedContractAbi: any;
  currentPeriod: number;
  refetch: any;
}) => {
  const [userDepositIds, setUserDepositIds] = useState<OwnedNft[]>([]);
  const [pools, setPools] = useState<DepositPool[]>([]);

  useEffect(() => {
    async function fetchUserDepositIds() {
      if (!address || !deployedContractAddress) return;

      try {
        const _userDepositIds = await getNFTsForOwner(chainId, address, deployedContractAddress);
        if (_userDepositIds?.length > 0) {
          setUserDepositIds(_userDepositIds as OwnedNft[]);
        }
      } catch (error) {
        console.error("Error fetching user deposit IDs:", error);
      }
    }

    fetchUserDepositIds();
  }, [address, chainId, deployedContractAddress]);

  useEffect(() => {
    async function fetchBalances() {
      if (!deployedContractAddress || !address || userDepositIds.length === 0) return;

      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
      const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);

      const balancePromises = userDepositIds.map(async depositId => {
        try {
          const balanceBigInt = await contract.balanceOf(address, depositId);
          const balance = ethers.formatUnits(balanceBigInt, 6);

          const sharesBigInt = await contract.sharesAtPeriod(address, depositId);
          const shares = ethers.formatUnits(sharesBigInt, 6);

          const unlockRequestAmountBigInt = await contract.unlockRequestAmountByDepositPeriod(
            address,
            Number(depositId),
          );
          const unlockRequestAmount = ethers.formatUnits(unlockRequestAmountBigInt, 6);

          if (balanceBigInt > 0 && Number(depositId) <= currentPeriod) {
            const yieldAmount =
              currentPeriod > Number(depositId) ? await contract.calcYield(balanceBigInt, depositId, currentPeriod) : 0;

            return {
              depositId,
              balance,
              shares,
              unlockRequestAmount,
              yield: yieldAmount > 0 ? ethers.formatUnits(yieldAmount, 6) : yieldAmount,
            };
          }

          return null;
        } catch (error) {
          console.error(
            "Error fetching balance for depositId:",
            depositId,
            " and currentPeriod: ",
            currentPeriod,
            error,
          );
          return null;
        }
      });

      const results = await Promise.all(balancePromises);
      const validPools = results.filter(pool => pool !== null) as DepositPool[];

      setPools(validPools);
    }

    if (userDepositIds.length > 0 && deployedContractAddress) {
      fetchBalances();
    }
  }, [refetch, userDepositIds, deployedContractAddress, deployedContractAbi, address, currentPeriod]);

  return { pools };
};
