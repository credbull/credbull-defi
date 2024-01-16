import { ERC20__factory } from '@credbull/contracts';
import { Address } from 'abitype/src/abi';
import { formatEther } from 'viem';
import { useContractRead } from 'wagmi';

export type BalanceOfProps = {
  erc20Address: string;
  address: string | undefined;
  enabled?: boolean;
};

export function BalanceOf(props: BalanceOfProps) {
  const { data } = useContractRead({
    address: props.erc20Address as Address,
    abi: ERC20__factory.abi,
    functionName: 'balanceOf',
    watch: true,
    args: [props.address as Address],
    enabled: props.enabled,
  });

  return <>{formatEther(data ?? BigInt(0))}</>;
}
