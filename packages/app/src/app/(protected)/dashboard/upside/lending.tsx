'use client';

import { Tables } from '@credbull/api';
import {
  CredbullWhiteListProvider__factory,
  ERC20__factory,
  ERC4626__factory,
  FixedYieldVault__factory,
} from '@credbull/contracts';
import { Badge, Button, Card, Flex, Group, NumberInput, SimpleGrid, Text } from '@mantine/core';
import { zodResolver } from '@mantine/form';
import { useClipboard } from '@mantine/hooks';
import { useList, useNotification } from '@refinedev/core';
import { useForm } from '@refinedev/mantine';
import { IconCopy } from '@tabler/icons';
import { format, isAfter, isBefore, parseISO } from 'date-fns';
import { utils } from 'ethers';
import _ from 'lodash';
import { useEffect, useState } from 'react';
import { formatEther } from 'viem';
import { waitForTransactionReceipt } from 'viem/actions';
import { Address, useAccount, useContractRead, useContractWrite, useWalletClient } from 'wagmi';
import { z } from 'zod';

import { BalanceOf } from '@/components/contracts/balance-of';

const schema = z.object({
  amount: z.number().positive(),
});

type VaultProps = {
  data: Tables<'vaults'>[];
  entities: Tables<'vault_entities'>[];
  isConnected: boolean;
  address: Address;
  mockTokenAddress?: string;
};

function Vault(props: VaultProps) {
  const clipboard = useClipboard();
  const { open } = useNotification();
  const isMatured = props.data[0].status === 'matured';

  const whiteListProvider = _.find(props.entities, { type: 'whitelist_provider' });
  const custodian = _.find(props.entities, { type: 'custodian' });
  const reward = _.find(props.entities, { type: 'activity_reward' });

  useEffect(() => {
    if (clipboard.copied) {
      open?.({ type: 'success', message: `Address copied!` });
    }
  }, [clipboard.copied, open]);

  const { data: whiteListStatus } = useContractRead({
    address: whiteListProvider?.address as Address,
    abi: CredbullWhiteListProvider__factory.abi,
    functionName: 'status',
    watch: true,
    args: [props.address as Address],
    enabled: !!whiteListProvider?.address && !!props.address,
  });

  const { data: vaultTotalAssets0 } = useContractRead({
    address: props.data[0].address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'totalAssets',
    watch: true,
    enabled: !!props.data[0].address,
  });

  const { data: vaultTotalAssets1 } = useContractRead({
    address: props.data[1].address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'totalAssets',
    watch: true,
    enabled: !!props.data[1].address,
  });

  const name = 'Fixed Yield (+ Upside)';

  const redemptionsOpen = parseISO(props.data[0].redemptions_opened_at);
  const redemptionsClose = parseISO(props.data[0].redemptions_closed_at);

  const depositsOpen = parseISO(props.data[0].deposits_opened_at);
  const depositsClose = parseISO(props.data[0].deposits_closed_at);
  const opened = isAfter(new Date(), depositsOpen) && isBefore(new Date(), depositsClose);

  const upsideVault = props.data.find((vault) => vault.type === 'fixed_yield_upside')!;
  const normalVault = props.data.find((vault) => vault.type === 'fixed_yield')!;

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Group position="apart" mt="md" mb="xs">
        <Button
          variant="white"
          p="0"
          onClick={() => clipboard.copy(`${props.data[0].address} || ${props.data[1].address}`)}
        >
          <Text weight={500} color="black" fz="lg">
            {name} <IconCopy size={12} />
          </Text>
        </Button>
        <Badge color={isMatured ? 'orange' : opened ? 'green' : 'pink'} variant="light">
          {isMatured ? 'Claimable' : opened ? 'Open' : 'Closed'}
        </Badge>
      </Group>

      <Group position="apart" mt="xl" mb="xs">
        <Text size="sm" color="gray">
          Vault Deposits Open
        </Text>
        <Text size="sm" color="gray">
          {format(depositsOpen, 'MM/dd/yyyy HH:mm')}
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Vault Deposits Close
        </Text>
        <Text size="sm" color="gray">
          {format(depositsClose, 'MM/dd/yyyy HH:mm')}
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Vault Redemption Open
        </Text>
        <Text size="sm" color="gray">
          {format(redemptionsOpen, 'MM/dd/yyyy HH:mm')}
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Vault Redemption Close
        </Text>
        <Text size="sm" color="gray">
          {format(redemptionsClose, 'MM/dd/yyyy HH:mm')}
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Vault Total Assets
        </Text>
        <Text size="sm" color="gray">
          {vaultTotalAssets0 && vaultTotalAssets1
            ? parseFloat(formatEther(vaultTotalAssets0 + vaultTotalAssets1)).toFixed(2)
            : '0'}{' '}
          USDC
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Vault USDC Balance (Upside)
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!upsideVault.asset_address && !!upsideVault.address}
            erc20Address={upsideVault.asset_address}
            address={upsideVault.address}
          />{' '}
          USDC
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Vault USDC Balance
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!normalVault.asset_address && !!normalVault.address}
            erc20Address={normalVault.asset_address}
            address={normalVault.address}
          />{' '}
          USDC
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Vault CBL Balance
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!props.mockTokenAddress && !!upsideVault.address}
            erc20Address={props.mockTokenAddress!}
            address={upsideVault.address}
            unit={18}
          />{' '}
          CBL
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray" onClick={() => clipboard.copy(custodian?.address)} style={{ cursor: 'pointer' }}>
          Circle Balance <IconCopy size={12} />
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!props.data[0].asset_address && !!custodian?.address}
            erc20Address={props.data[0].asset_address}
            address={custodian?.address}
          />{' '}
          USDC
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Reward Pool Balance
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!props.data[0].asset_address && !!reward?.address}
            erc20Address={props.data[0].asset_address}
            address={reward?.address}
          />{' '}
          USDC
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Your Claim Tokens (Upside)
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!upsideVault.address && !!props.address}
            erc20Address={upsideVault.address}
            address={props.address}
          />{' '}
          TOKENS
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Your Claim Tokens
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!normalVault.address && !!props.address}
            erc20Address={normalVault.address}
            address={props.address}
          />{' '}
          TOKENS
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Your White List Status
        </Text>
        <Text size="sm" color="gray">
          {whiteListStatus ? 'Active' : 'Inactive'}
        </Text>
      </Group>

      <VaultActions
        data={upsideVault}
        entities={props.entities}
        isConnected={props.isConnected}
        mockTokenAddress={props.mockTokenAddress}
        address={props.address}
        upside={true}
      />
      <VaultActions
        data={normalVault}
        entities={props.entities}
        isConnected={props.isConnected}
        mockTokenAddress={props.mockTokenAddress}
        address={props.address}
        upside={false}
      />
    </Card>
  );
}

type VaultActionsProps = {
  data: Tables<'vaults'>;
  entities: Tables<'vault_entities'>[];
  isConnected: boolean;
  address: Address;
  mockTokenAddress?: string;
  upside: boolean;
};

function VaultActions(props: VaultActionsProps) {
  const { open } = useNotification();
  const [isLoading, setLoading] = useState(false);
  const { data: client } = useWalletClient();
  const isMatured = props.data.status === 'matured';

  const form = useForm({
    validate: zodResolver(schema),
    initialValues: {
      amount: 0,
    },
  });

  console.log(props.data);

  const { data: userBalance } = useContractRead({
    address: props.data.address as Address,
    abi: ERC20__factory.abi,
    functionName: 'balanceOf',
    watch: true,
    args: [props.address as Address],
    enabled: !!props.data.address && !!props.address,
  });

  console.log(props.mockTokenAddress);

  const { writeAsync: approveTokenAsync } = useContractWrite({
    address: props.mockTokenAddress as Address,
    abi: ERC4626__factory.abi,
    functionName: 'approve',
    args: [props.data.address as Address, utils.parseUnits((form.values.amount ?? 0).toString(), 18).toBigInt()],
  });

  const { writeAsync: approveAsync } = useContractWrite({
    address: props.data.asset_address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'approve',
    args: [props.data.address as Address, utils.parseUnits((form.values.amount ?? 0).toString(), 'mwei').toBigInt()],
  });

  const { writeAsync: depositAsync } = useContractWrite({
    address: props.data.address as Address,
    abi: FixedYieldVault__factory.abi,
    functionName: 'deposit',
    args: [utils.parseUnits((form.values.amount ?? 0).toString(), 'mwei').toBigInt(), props.address],
  });

  const { writeAsync: claimAsync } = useContractWrite({
    address: props.data.address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'redeem',
    args: [userBalance!, props.address, props.address],
  });

  const onDeposit = async () => {
    setLoading(true);
    try {
      if (props.data.type === 'fixed_yield_upside') {
        const approveTokenTx = await approveTokenAsync();
        await waitForTransactionReceipt(client!, approveTokenTx);
      }

      const approveTx = await approveAsync();

      if (client && approveTx.hash) {
        await waitForTransactionReceipt(client!, approveTx);
        const depositTx = await depositAsync();
        await waitForTransactionReceipt(client!, depositTx);
        form.reset();
        open?.({ type: 'success', message: 'Deposit successful' });
      }
    } catch (e) {
      open?.({ type: 'error', description: 'Deposit failed', message: e?.toString() ?? '' });
    } finally {
      setLoading(false);
    }
  };

  const onRedeem = async () => {
    setLoading(true);
    try {
      const claimTx = await claimAsync();
      await waitForTransactionReceipt(client!, claimTx);
      open?.({ type: 'success', message: 'Claim successful' });
    } catch (e) {
      open?.({ type: 'error', description: 'Claim failed', message: e?.toString() ?? '' });
    } finally {
      setLoading(false);
    }
  };

  const depositsOpen = parseISO(props.data.deposits_opened_at);
  const depositsClose = parseISO(props.data.deposits_closed_at);
  const opened = isAfter(new Date(), depositsOpen) && isBefore(new Date(), depositsClose);

  return isMatured ? (
    <Group mt="xl" grow>
      <Button
        onClick={() => onRedeem()}
        variant="light"
        color="blue"
        mt="md"
        radius="md"
        disabled={!props.isConnected || Number(userBalance) === 0 || isLoading}
        loading={isLoading}
      >
        Claim {props.upside ? 'with Upside' : ''}
      </Button>
    </Group>
  ) : (
    <form onSubmit={form.onSubmit(() => onDeposit())}>
      <Group mt="xl" grow>
        <NumberInput
          label="Deposit Amount"
          {...form.getInputProps('amount')}
          disabled={!props.isConnected || !opened || isLoading}
        />

        <Button
          type="submit"
          variant="light"
          color="blue"
          mt="md"
          radius="md"
          disabled={!props.isConnected || !opened || isLoading}
          loading={isLoading}
        >
          Deposit {props.upside ? 'with Upside' : ''}
        </Button>
      </Group>
    </form>
  );
}

type EntitiesBalancesProps = {
  name: string;
  entity?: Pick<Tables<'vault_entities'>, 'address'>;
  erc20Address?: string;
  unit?: number;
};
const EntityBalance = ({ entity, erc20Address, name, unit }: EntitiesBalancesProps) => {
  const { open } = useNotification();
  const clipboard = useClipboard();

  useEffect(() => {
    if (clipboard.copied) {
      open?.({ type: 'success', message: `${name} address copied!` });
    }
  }, [clipboard.copied, name, open]);

  return (
    <Flex direction="column" p="md" mr="md" justify="center" align="center">
      <Button variant="white" p="0" mt="sm" onClick={() => clipboard.copy(entity?.address)}>
        <Text size="sm" color="gray">
          {name} <IconCopy size={12} />
        </Text>
      </Button>

      <Text size="lg" weight={500}>
        {erc20Address && entity && (
          <BalanceOf
            enabled={!!erc20Address && !!entity}
            erc20Address={erc20Address!}
            address={entity?.address}
            unit={unit}
          />
        )}
      </Text>
    </Flex>
  );
};

export function Lending(props: { email?: string; status?: string; mockTokenAddress?: string }) {
  const { isConnected, address } = useAccount();
  const [mockTokenAddress, setMockTokenAddress] = useState<string | undefined>();

  const { data: entities } = useList<Tables<'vault_entities'>>({
    resource: 'vault_entities',
    pagination: { pageSize: 1000 },
  });

  useEffect(() => {
    if (props.mockTokenAddress) {
      setMockTokenAddress(props.mockTokenAddress);
    }
  }, [props.mockTokenAddress]);

  const { data: list, isLoading } = useList<Tables<'vaults'>>({
    resource: 'vaults',
    filters: [
      { field: 'status', operator: 'ne', value: 'created' },
      { field: 'deposits_opened_at', operator: 'lt', value: 'now()' },
    ],
    queryOptions: {
      refetchOnWindowFocus: 'always',
    },
    pagination: { pageSize: 1000 },
    sorters: [{ field: 'deposits_opened_at', order: 'desc' }],
  });

  const erc20Address = list?.data[0]?.asset_address;
  const treasury = _.find(entities?.data, { type: 'treasury' });

  const grouped = list
    ? _.groupBy(
        list.data.map((l) => {
          const depositsOpen = parseISO(l.deposits_opened_at);
          const depositsClose = parseISO(l.deposits_closed_at);

          return {
            ...l,
            open: isAfter(new Date(), depositsOpen) && isBefore(new Date(), depositsClose),
          };
        }),
        'open',
      )
    : {};
  return (
    <Flex justify="space-around" direction="column" gap="60px">
      <Flex justify="center" align="center" direction="row">
        <EntityBalance entity={{ address: address! }} erc20Address={erc20Address} name="You (USDC)" />
        <EntityBalance entity={{ address: address! }} erc20Address={mockTokenAddress} name="You (CBL)" unit={18} />
        <EntityBalance entity={treasury} erc20Address={erc20Address} name="Treasury (USDC)" />
      </Flex>

      <SimpleGrid cols={3}>
        {isLoading || !list ? (
          <>Loading...</>
        ) : (
          Object.keys(grouped).map((k) => (
            <Vault
              mockTokenAddress={mockTokenAddress}
              entities={_.filter(entities?.data, { vault_id: grouped[k][0].id })}
              key={grouped[k][0].id}
              data={grouped[k]}
              isConnected={isConnected}
              address={address!}
            />
          ))
        )}
      </SimpleGrid>
    </Flex>
  );
}
