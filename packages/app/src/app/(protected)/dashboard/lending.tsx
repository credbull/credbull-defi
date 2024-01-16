'use client';

import { Tables } from '@credbull/api';
import { ERC4626__factory } from '@credbull/contracts';
import { Badge, Button, Card, Flex, Group, NumberInput, Text } from '@mantine/core';
import { zodResolver } from '@mantine/form';
import { useList } from '@refinedev/core';
import { useForm } from '@refinedev/mantine';
import { format, isAfter, isBefore, parseISO } from 'date-fns';
import _ from 'lodash';
import { parseEther } from 'viem';
import { Address, useAccount, useContractWrite } from 'wagmi';
import { z } from 'zod';

import { BalanceOf } from '@/components/contracts/balance-of';

const schema = z.object({
  amount: z.number().positive(),
});

type VaultProps = {
  data: Tables<'vaults'>;
  isConnected: boolean;
  address: Address;
};

function Vault(props: VaultProps) {
  const form = useForm({
    validate: zodResolver(schema),
    initialValues: {
      amount: 0,
    },
  });

  const { writeAsync: approveAsync } = useContractWrite({
    address: props.data.asset_address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'approve',
    args: [props.data.address as Address, parseEther((form.values.amount ?? 0).toString())],
  });

  const { writeAsync: depositAsync } = useContractWrite({
    address: props.data.address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'deposit',
    args: [parseEther((form.values.amount ?? 0).toString()), props.address],
  });

  const { writeAsync: claimAsync } = useContractWrite({
    address: props.data.address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'redeem',
    args: [parseEther((form.values.amount ?? 0).toString()), props.address, props.address],
  });

  const onDeposit = async () => {
    await approveAsync();
    await depositAsync();
  };

  const onRedeem = async () => {
    await claimAsync();
  };

  const name = props.data.type === 'fixed_yield' ? 'Fixed Yield Vault' : 'Structured Yield Vault';

  const closes = parseISO(props.data.closed_at);
  const opens = parseISO(props.data.opened_at);
  const opened = isAfter(new Date(), opens) && isBefore(new Date(), closes);
  const isMatured = props.data.status === 'matured';
  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Group position="apart" mt="md" mb="xs">
        <Text weight={500}>{name}</Text>
        <Badge color="pink" variant="light">
          {isMatured ? 'Claimable' : opened ? 'Open' : 'Closed'}
        </Badge>
      </Group>

      <Group position="apart" mt="xl" mb="xs">
        <Text size="sm" color="gray">
          Opens
        </Text>
        <Text size="sm" color="gray">
          {format(opens, 'MM/dd/yyyy HH:mm')}
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Closes
        </Text>
        <Text size="sm" color="gray">
          {format(closes, 'MM/dd/yyyy HH:mm')}
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Total Deposited
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!props.data.asset_address && !!props.data.address}
            erc20Address={props.data.asset_address}
            address={props.data.address}
          />{' '}
          USDC
        </Text>
      </Group>

      <Group position="apart" mt="md" mb="xs">
        <Text size="sm" color="gray">
          Your Deposit
        </Text>
        <Text size="sm" color="gray">
          <BalanceOf
            enabled={!!props.data.address && !!props.address}
            erc20Address={props.data.address}
            address={props.address}
          />{' '}
          USDC
        </Text>
      </Group>

      <form onSubmit={form.onSubmit(() => (isMatured ? onRedeem() : onDeposit()))}>
        <Group mt="xl">
          <NumberInput
            label={isMatured ? 'Claim Amount' : 'Deposit Amount'}
            {...form.getInputProps('amount')}
            disabled={!props.isConnected || (isMatured ? false : !opened)}
          />

          <Button
            type="submit"
            variant="light"
            color="blue"
            mt="md"
            radius="md"
            disabled={!props.isConnected || (isMatured ? false : !opened)}
          >
            {isMatured ? 'Claim' : 'Deposit'}
          </Button>
        </Group>
      </form>
    </Card>
  );
}

type EntitiesBalancesProps = {
  name: string;
  entity?: Pick<Tables<'vault_distribution_entities'>, 'address'>;
  erc20Address?: string;
};
const EntityBalance = ({ entity, erc20Address, name }: EntitiesBalancesProps) => {
  return (
    <Flex direction="column" p="md" mr="md" justify="center" align="center">
      <Text size="sm" color="gray" mt="sm">
        {name}
      </Text>
      <Text size="lg" weight={500}>
        <BalanceOf enabled={!!erc20Address && !!entity} erc20Address={erc20Address!} address={entity?.address} /> USDC
      </Text>
    </Flex>
  );
};

export function Lending(props: { email?: string; status?: string }) {
  const { isConnected, address } = useAccount();

  const { data: entities } = useList<Tables<'vault_distribution_entities'>>({
    resource: 'vault_distribution_entities',
    meta: { select: 'type, address' },
  });

  const { data: list, isLoading } = useList<Tables<'vaults'>>({
    resource: 'vaults',
    filters: [
      { field: 'status', operator: 'ne', value: 'created' },
      { field: 'opened_at', operator: 'lt', value: 'now()' },
    ],
  });

  const erc20Address = list?.data[0].asset_address;
  const custodian = _.find(entities?.data, { type: 'custodian' });
  const treasury = _.find(entities?.data, { type: 'treasury' });
  const activity = _.find(entities?.data, { type: 'activity_reward' });

  return (
    <Flex justify="space-around" direction="column" gap="60px">
      <Flex justify="center" align="center" direction="row">
        <EntityBalance entity={{ address: address! }} erc20Address={erc20Address} name="You" />
        <EntityBalance entity={treasury} erc20Address={erc20Address} name="Treasury" />
        <EntityBalance entity={activity} erc20Address={erc20Address} name="Activity Reward" />
        <EntityBalance entity={custodian} erc20Address={erc20Address} name="Custodian" />
      </Flex>

      <Flex justify="center" gap="30px">
        {isLoading || !list ? (
          <>Loading...</>
        ) : (
          list.data.map((val) => <Vault key={val.id} data={val} isConnected={isConnected} address={address!} />)
        )}
      </Flex>
    </Flex>
  );
}
