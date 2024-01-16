import { ERC20__factory } from '@credbull/contracts';
import { Address } from 'abitype/src/abi';
import { useContractRead } from 'wagmi';

export type BalanceOfProps = {
  erc20Address: string;
  address: string | undefined;
  enabled?: boolean;
};

export function BalanceOf(props: BalanceOfProps) {
  const { data, error } = useContractRead({
    address: props.erc20Address as Address,
    abi: ERC20__factory.abi,
    functionName: 'balanceOf',
    watch: true,
    args: [props.address as Address],
    enabled: props.enabled,
  });

  console.log(props.enabled);
  console.log(error);
  console.log(data);

  return <>{data?.toString()}</>;
}
