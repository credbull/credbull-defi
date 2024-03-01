import { ERC20__factory } from '@credbull/contracts';
import { Address } from 'abitype/src/abi';
import { BigNumber, utils } from 'ethers';
import { formatEther } from 'viem';
import { useContractRead } from 'wagmi';

export type BalanceOfProps = {
  erc20Address: string;
  address: string | undefined;
  enabled?: boolean;
  unit?: number | undefined;
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

  const value = utils.formatUnits(data?.toString() ?? '0', props.unit ?? 6);

  return <>{parseFloat(value).toFixed(value.includes('.') ? 2 : 0)}</>;
}
