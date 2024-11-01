import { useEffect, useState } from "react";
import { OwnedNft } from "alchemy-sdk";
import { ethers } from "ethers";
import { useChainId, useChains } from "wagmi";
import { DepositPool } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";
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
  const chains = useChains();
  const chianId = useChainId();

  const chain = chains?.filter(_chain => _chain?.id === chianId)[0];

  const [depositPoolsFetched, setDepositPoolsFetched] = useState<boolean>(true);

  const [userDepositIds, setUserDepositIds] = useState<OwnedNft[]>([]);
  const [fetchedWithAlchemy, setFetchedWithAlchemy] = useState<boolean>(false);
  const [existingUserDepositIds, setExistingUserDepositIds] = useState<OwnedNft[]>([]);
  const [pools, setPools] = useState<DepositPool[]>([]);

  useEffect(() => {
    setDepositPoolsFetched(false);

    async function fetchUserDepositIds() {
      if (!chainId || !address || !deployedContractAddress) return;

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
      }
    }

    fetchUserDepositIds();
  }, [address, chainId, deployedContractAddress]);

  useEffect(() => {
    setDepositPoolsFetched(false);

    async function fetchExistingUserDepositIds() {
      if (!deployedContractAddress || !deployedContractAbi || fetchedWithAlchemy) return;

      try {
        const provider = new ethers.JsonRpcProvider(chain?.rpcUrls?.default?.http[0]);
        const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);

        const existingUserDepositIds: OwnedNft[] = [];

        for (let i = 0; i < userDepositIds.length; i++) {
          const depositId = userDepositIds[i];

          const exists = await contract.exists(depositId?.tokenId);
          if (exists) {
            existingUserDepositIds.push(depositId);
          }
        }

        if (existingUserDepositIds?.length > 0) {
          setExistingUserDepositIds(existingUserDepositIds as OwnedNft[]);
        }
      } catch (error) {
        console.error("Error fetching existing user deposit IDs:", error);
      }
    }

    fetchExistingUserDepositIds();
  }, [
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
      )
        return;

      const provider = new ethers.JsonRpcProvider(chain?.rpcUrls?.default?.http[0]);
      const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);

      const balancePromises = existingUserDepositIds.map(async depositId => {
        try {
          let balanceBigInt;

          if (fetchedWithAlchemy) {
            balanceBigInt = BigInt(depositId?.balance);
          } else {
            balanceBigInt = await contract.balanceOf(address, depositId?.tokenId);
          }

          const balance = ethers.formatUnits(balanceBigInt, 6);

          const sharesBigInt = await contract.sharesAtPeriod(address, depositId?.tokenId);
          const shares = ethers.formatUnits(sharesBigInt, 6);

          const unlockRequestAmountBigInt = await contract.unlockRequestAmountByDepositPeriod(
            address,
            Number(depositId?.tokenId),
          );
          const unlockRequestAmount = ethers.formatUnits(unlockRequestAmountBigInt, 6);

          if (balanceBigInt > 0 && Number(depositId?.tokenId) <= currentPeriod) {
            let yieldAmount = 0;

            try {
              yieldAmount =
                currentPeriod > Number(depositId?.tokenId)
                  ? await contract.calcYield(balanceBigInt, depositId?.tokenId, currentPeriod)
                  : 0;
            } catch (error) {
              yieldAmount = 0;

              notification.warning(
                "It seems like you are testing a wrong scenario! You may set the reduced rate and get back to a period where it is not effective anymore. So you will see a wrong number regarding the `Yield Amount`.",
              );
            }

            return {
              depositId: depositId?.tokenId,
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
            depositId?.tokenId,
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
      setDepositPoolsFetched(true);
    }

    if (fetchedWithAlchemy) {
      if (existingUserDepositIds.length > 0 && deployedContractAddress) {
        try {
          fetchBalances();
        } catch (error) {
          console.log(error);
          setDepositPoolsFetched(true);
        }
      }
    } else {
      if (userDepositIds.length > 0 && deployedContractAddress) {
        try {
          fetchBalances();
        } catch (error) {
          console.log(error);
          setDepositPoolsFetched(true);
        }
      }
    }
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

  return { pools, depositPoolsFetched };
};
