import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { useReadContract } from "wagmi";
import { PeriodRate } from "~~/types/vault";
import { Contract, ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";
import { formatTimestamp } from "~~/utils/vault/general";

export const useFetchContractData = ({
  deployedContractAddress,
  deployedContractAbi,
  simpleUsdcContractData,
  dependencies = [],
}: {
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  simpleUsdcContractData: Contract<ContractName> | undefined;
  dependencies: [any] | [];
}) => {
  const [currentPeriod, setCurrentPeriod] = useState<number>(0);
  const [assetAmount, setAssetAmount] = useState<string>("");
  const [startTimeNumber, setStartTimeNumber] = useState<bigint>(BigInt(0));
  const [startTime, setStartTime] = useState<string>("");
  const [noticePeriod, setNoticePeriod] = useState<number>(0);
  const [frequency, setFrequency] = useState<number>(0);
  const [tenor, setTenor] = useState<number>(0);
  const [scale, setScale] = useState<number>(0);
  const [fullRate, setFullRate] = useState<number>(0);
  const [reducedRate, setReducedRate] = useState<number>(0);

  const { refetch: refetchCurrentPeriod } = useReadContract({
    address: deployedContractAddress,
    functionName: "currentPeriodsElapsed",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchAssetAmount } = useReadContract({
    address: simpleUsdcContractData?.address,
    functionName: "balanceOf",
    abi: simpleUsdcContractData?.abi,
    args: [deployedContractAddress],
  });

  const { refetch: refetchStartTime } = useReadContract({
    address: deployedContractAddress,
    functionName: "_vaultStartTimestamp",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchNoticePeriod } = useReadContract({
    address: deployedContractAddress,
    functionName: "noticePeriod",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchFrequency } = useReadContract({
    address: deployedContractAddress,
    functionName: "frequency",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchTenor } = useReadContract({
    address: deployedContractAddress,
    functionName: "numPeriodsForFullRate",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchScale } = useReadContract({
    address: deployedContractAddress,
    functionName: "scale",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchFullRate } = useReadContract({
    address: deployedContractAddress,
    functionName: "rateScaled",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchReducedRate } = useReadContract({
    address: deployedContractAddress,
    functionName: "currentPeriodRate",
    abi: deployedContractAbi,
    args: [],
  });

  // Fetch data and set state
  useEffect(() => {
    const fetchData = async () => {
      const currentPeriodData = await refetchCurrentPeriod();
      setCurrentPeriod(Number(currentPeriodData?.data));

      const assetAmountData = await refetchAssetAmount();
      const assetAmountBigInt = BigInt(assetAmountData?.data as bigint);
      setAssetAmount(ethers.formatUnits(assetAmountBigInt, 6));

      const startTimeData = await refetchStartTime();
      setStartTimeNumber(startTimeData?.data as bigint);
      setStartTime(formatTimestamp(Number(startTimeData?.data)));

      const noticePeriodData = await refetchNoticePeriod();
      setNoticePeriod(Number(noticePeriodData?.data));

      const frequencyData = await refetchFrequency();
      setFrequency(Number(frequencyData?.data));

      const tenorData = await refetchTenor();
      setTenor(Number(tenorData?.data));

      const scaleData = await refetchScale();
      setScale(Number(scaleData?.data));

      const fullRateData = await refetchFullRate();
      if (scale > 0) {
        setFullRate(Number(fullRateData?.data) / scale);
      }

      const reducedRateData = await refetchReducedRate();
      if (scale > 0) {
        setReducedRate(Number((reducedRateData?.data as PeriodRate)?.interestRate) / scale);
      }
    };

    fetchData();
  }, [
    deployedContractAddress,
    simpleUsdcContractData,
    refetchCurrentPeriod,
    refetchAssetAmount,
    refetchStartTime,
    refetchNoticePeriod,
    refetchFrequency,
    refetchTenor,
    refetchScale,
    refetchFullRate,
    refetchReducedRate,
    scale,
    ...dependencies,
  ]);

  return {
    currentPeriod,
    assetAmount,
    startTimeNumber,
    startTime,
    noticePeriod,
    frequency,
    tenor,
    scale,
    fullRate,
    reducedRate,
  };
};
