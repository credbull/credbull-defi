import { useState, useEffect, useCallback } from "react";
import { useReadContract } from "wagmi";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";

interface TableRow {
  requestId: number;
  unlockAmount: bigint;
}

interface DetailRow {
  depositPeriod: number;
  amount: bigint;
}

interface UseRequestDataParams {
  proxyAddress: string;
  abi: ContractAbi;
  userAddress: string;
  maxPeriod: number;
}

export const useRequestData = ({
  proxyAddress,
  abi,
  userAddress,
  maxPeriod,
}: UseRequestDataParams) => {
  const [rows, setRows] = useState<TableRow[]>([]);
  const [details, setDetails] = useState<DetailRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Pre-create the hooks with args fixed
  const unlockRequestHooks = Array.from({ length: maxPeriod + 1 }, (_, i) =>
    useReadContract({
      address: proxyAddress,
      abi,
      functionName: "unlockRequestAmount",
      args: [userAddress, BigInt(i)],
    })
  );

  const fetchRequests = useCallback(async () => {
    try {
      const newRows: TableRow[] = [];

      // Fetch all requests using pre-initialized hooks
      for (let i = 0; i <= maxPeriod; i++) {
        const { data } = await unlockRequestHooks[i].refetch();
        const amount = BigInt(data || 0);
        if (amount > 0) {
          newRows.push({ requestId: i, unlockAmount: amount });
        }
      }

      setRows(newRows);
    } catch (err) {
      console.error("Error fetching request data:", err);
      setError("Failed to fetch request data");
    }
  }, [unlockRequestHooks]);

  const fetchDetails = useCallback(
    async (requestId: number) => {
      setLoading(true);

      try {
        const { data } = await useReadContract({
          address: proxyAddress,
          abi,
          functionName: "unlockRequests",
          args: [userAddress, BigInt(requestId)],
        }).refetch();

        const [depositPeriods, amounts] = data as [bigint[], bigint[]];
        const unlockDetails = depositPeriods.map((period, index) => ({
          depositPeriod: Number(period),
          amount: amounts[index],
        }));

        setDetails(unlockDetails);
      } catch (err) {
        console.error("Error fetching unlock details:", err);
        setError("Failed to fetch unlock details");
        setDetails([]);
      } finally {
        setLoading(false);
      }
    },
    [proxyAddress, abi, userAddress]
  );

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  return {
    rows,
    details,
    loading,
    error,
    fetchDetails,
  };
};
