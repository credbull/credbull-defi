import { useEffect, useState } from "react";
import { OwnedNft } from "alchemy-sdk";
import { ethers } from "ethers";
import { useChainId, useChains } from "wagmi";
import { DepositPool } from "~~/types/vault";
import { getProvider } from "~~/utils/scaffold-eth";
import { getNFTsForOwner } from "~~/utils/vault/web3";

export const useFetchDepositPools = ({
  address,
  deployedContractAddress,
  deployedContractAbi,
  currentPeriod,
  refetch,
}: {
  address: string;
  deployedContractAddress: string;
  deployedContractAbi: any;
  currentPeriod: number;
  refetch: any;
}) => {
  const chains = useChains();
  const chainId = useChainId();

  const chain = chains?.filter(_chain => _chain?.id === chainId)[0];

  const [depositPoolsFetched, setDepositPoolsFetched] = useState<boolean>(!!address);

  const [userDepositIds, setUserDepositIds] = useState<OwnedNft[]>([]);
  const [fetchedWithAlchemy, setFetchedWithAlchemy] = useState<boolean>(false);
  const [existingUserDepositIds, setExistingUserDepositIds] = useState<OwnedNft[]>([]);
  const [pools, setPools] = useState<DepositPool[]>([]);

  useEffect(() => {
    setDepositPoolsFetched(false);

    async function fetchUserDepositIds() {
      if (!chainId || !address || !deployedContractAddress) {
        setDepositPoolsFetched(true);
        return;
      }

      try {
        const { nfts: _userDepositIds, fetchedWithAlchemy: _fetchedWithAlchemy } = await getNFTsForOwner(
          chainId,
          address,
          deployedContractAddress,
        );
        setFetchedWithAlchemy(_fetchedWithAlchemy);

        if (_userDepositIds?.length > 0) {
          if (_fetchedWithAlchemy) {
            setExistingUserDepositIds(_userDepositIds as OwnedNft[]);
          } else {
            setUserDepositIds(_userDepositIds as OwnedNft[]);
          }
        }
      } catch (error) {
        console.error("Error fetching user deposit IDs:", error);
        setDepositPoolsFetched(true);
      }
    }

    fetchUserDepositIds();
  }, [address, chainId, deployedContractAddress]);

  useEffect(() => {
    setDepositPoolsFetched(false);

    (async () => {
      if (!deployedContractAddress || !deployedContractAbi || fetchedWithAlchemy || !currentPeriod) {
        setDepositPoolsFetched(true);
        return;
      }

      // getNFTsForOwner() returns only our own tokens
      setExistingUserDepositIds(userDepositIds);
      setDepositPoolsFetched(true);
    })();
  }, [
    currentPeriod,
    userDepositIds,
    fetchedWithAlchemy,
    chainId,
    deployedContractAddress,
    deployedContractAbi,
    chain?.rpcUrls?.default?.http,
  ]);

  useEffect(() => {
    setDepositPoolsFetched(false);

    async function fetchBalances() {
      if (
        !chain?.rpcUrls?.default?.http ||
        !deployedContractAddress ||
        !deployedContractAbi ||
        !address ||
        existingUserDepositIds.length === 0 ||
        !chain?.rpcUrls?.default?.http[0]
      ) {
        setDepositPoolsFetched(true);
        return;
      }

      const provider = await getProvider(chain);

      const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);

      const depositIds: bigint[] = existingUserDepositIds.map(d => BigInt(d.tokenId));
      const accounts: string[] = depositIds.map(() => address);

      // clone the shares into a proper array.  ethers returns a frozen Result array.
      const shares = [...(await contract.balanceOfBatch(accounts, depositIds))] as bigint[];
      const assets = await contract.convertToAssetsForDepositPeriodBatch(shares, depositIds, currentPeriod);

      const poolMap = new Map<bigint, DepositPool>();

      for (let i = 0; i < depositIds.length; i++) {
        const depositId = depositIds[i];
        const sharesAtDepositId = shares[i];
        const assetsAtDepositId = assets[i];

        const unlockRequestAmount = await contract.unlockRequestAmountByDepositPeriod(address, depositId);

        if (sharesAtDepositId > 0n && Number(depositId) <= currentPeriod) {
          poolMap.set(depositId, {
            depositId,
            shares: sharesAtDepositId,
            assets: assetsAtDepositId,
            unlockRequestAmount,
            yield: assetsAtDepositId - sharesAtDepositId,
          });
        }
      }
      setPools(Array.from(poolMap.values()));

      setDepositPoolsFetched(true);
    }

    (async () => {
      if (existingUserDepositIds.length > 0 && deployedContractAddress) {
        try {
          await fetchBalances();
        } catch (error) {
          console.error(error);
          setDepositPoolsFetched(true);
        }
      } else {
        setDepositPoolsFetched(true);
      }
    })();
  }, [
    address,
    refetch,
    deployedContractAddress,
    deployedContractAbi,
    currentPeriod,
    fetchedWithAlchemy,
    userDepositIds,
    existingUserDepositIds,
    chain?.rpcUrls?.default?.http,
  ]);

  if (!address) {
    return { pools: [], depositPoolsFetched: true };
  }

  return { pools, depositPoolsFetched };
};
