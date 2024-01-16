'use client';

import { Tables } from '@credbull/api';
import { ERC4626__factory, MockStablecoin__factory } from '@credbull/contracts';
import { Button, Card, Flex, Group, NumberInput, Text, TextInput } from '@mantine/core';
import { zodResolver } from '@mantine/form';
import { useList } from '@refinedev/core';
import { useForm } from '@refinedev/mantine';
import { getPublicClient } from '@wagmi/core';
import { createWalletClient, http, parseEther } from 'viem';
import { waitForTransactionReceipt } from 'viem/actions';
import { Address, useAccount, useBalance, useContractWrite, useWalletClient } from 'wagmi';
import { foundry } from 'wagmi/chains';
import { z } from 'zod';

import { BalanceOf } from '@/components/contracts/balance-of';

const mintSchema = z.object({ amount: z.number().positive() });

const MintUSDC = ({ erc20Address }: { erc20Address: string }) => {
  const { isConnected, address } = useAccount();
  const { data: client } = useWalletClient();

  const form = useForm({
    validate: zodResolver(mintSchema),
    initialValues: {
      amount: 0,
    },
  });

  const { writeAsync } = useContractWrite({
    address: erc20Address as Address,
    abi: MockStablecoin__factory.abi,
    functionName: 'mint',
    args: [address as Address, parseEther((form.values.amount ?? 0).toString())],
  });

  const onMint = async () => {
    const mintTx = await writeAsync();
    await waitForTransactionReceipt(client!, mintTx);
  };

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Text weight={500}>Mint &quot;USDC&quot;</Text>
        </Group>

        <Group position="apart" mt="md" mb="xs">
          <Text size="sm" color="gray">
            Total Balance
          </Text>
          <Text size="sm" color="gray">
            <BalanceOf enabled={!!erc20Address && !!address} erc20Address={erc20Address ?? ''} address={address} /> USDC
          </Text>
        </Group>
        <form onSubmit={form.onSubmit(() => onMint())} style={{ marginTop: 'auto' }}>
          <Group>
            <NumberInput label="Amount" {...form.getInputProps('amount')} disabled={!isConnected} />
          </Group>
          <Group grow>
            <Button type="submit" variant="light" color="blue" mt="md" radius="md" disabled={!isConnected}>
              Mint
            </Button>
          </Group>
        </form>
      </Flex>
    </Card>
  );
};

const FAUCET_ADDRESS = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
const localWalletClient = createWalletClient({ chain: foundry, transport: http() });

const SendEth = () => {
  const { isConnected, address } = useAccount();
  const { data: ethBalance } = useBalance({ address, watch: true });

  const sendETH = async () => {
    try {
      const hash = await localWalletClient.sendTransaction({
        chain: foundry,
        account: FAUCET_ADDRESS,
        to: address,
        value: parseEther('10'),
      });

      const publicClient = getPublicClient();
      await publicClient.waitForTransactionReceipt({ hash });
    } catch (error) {
      console.error('⚡️ ~ file: FaucetButton.tsx:sendETH ~ error', error);
    }
  };

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Text weight={500}>Send ETH</Text>
        </Group>

        <Group position="apart" mt="md" mb="xs">
          <Text size="sm" color="gray">
            Total Balance
          </Text>
          <Text size="sm" color="gray">
            {parseFloat(ethBalance?.formatted ?? '0').toFixed(3)} ETH
          </Text>
        </Group>

        <Group position="apart" grow mt="auto">
          <Button onClick={() => sendETH()} variant="light" color="blue" mt="md" radius="md" disabled={!isConnected}>
            Send
          </Button>
        </Group>
      </Flex>
    </Card>
  );
};

const depositSchema = z.object({
  address: z.string().min(42).max(42),
  amount: z.number().positive(),
});

const VaultDeposit = ({ erc20Address }: { erc20Address: string }) => {
  const { isConnected, address } = useAccount();
  const { data: client } = useWalletClient();

  const form = useForm({
    validate: zodResolver(depositSchema),
    initialValues: { amount: 0, address: '' },
  });

  const { writeAsync: approveAsync } = useContractWrite({
    address: erc20Address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'approve',
    args: [form.values.address as Address, parseEther((form.values.amount ?? 0).toString())],
  });

  const { writeAsync: depositAsync } = useContractWrite({
    address: form.values.address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'deposit',
    args: [parseEther((form.values.amount ?? 0).toString()), address as Address],
  });

  const onDeposit = async () => {
    const approveTx = await approveAsync();
    if (client && approveTx.hash) {
      await waitForTransactionReceipt(client!, approveTx);
      const depositTx = await depositAsync();
      await waitForTransactionReceipt(client!, depositTx);
    }
  };

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Text weight={500}>Deposit Closed Vault</Text>
        </Group>

        <form onSubmit={form.onSubmit(() => onDeposit())} style={{ marginTop: 'auto' }}>
          <Group>
            <TextInput label="Address" {...form.getInputProps('address')} disabled={!isConnected} />
          </Group>

          <NumberInput label="Amount" {...form.getInputProps('amount')} disabled={!isConnected} />

          <Group grow>
            <Button type="submit" variant="light" color="blue" mt="md" radius="md" disabled={!isConnected}>
              Deposit
            </Button>
          </Group>
        </form>
      </Flex>
    </Card>
  );
};

export function Debug() {
  const { data: list, isLoading } = useList<Tables<'vaults'>>({
    resource: 'vaults',
    pagination: { pageSize: 1 },
  });

  const erc20Address = list?.data[0].asset_address;

  return isLoading ? (
    <>Loading...</>
  ) : (
    <Flex justify="space-around" direction="column" gap="60px">
      <Flex justify="center" gap="30px">
        <MintUSDC erc20Address={erc20Address ?? ''} />
        <SendEth />
        <VaultDeposit erc20Address={erc20Address ?? ''} />
      </Flex>
    </Flex>
  );
}
