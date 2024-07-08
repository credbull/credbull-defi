'use client';

import { Tables } from '@credbull/api';
import { ERC4626__factory, SimpleToken__factory, SimpleUSDC__factory } from '@credbull/contracts';
import { Button, Card, Flex, Group, NumberInput, SimpleGrid, Text, TextInput } from '@mantine/core';
import { zodResolver } from '@mantine/form';
import { useClipboard } from '@mantine/hooks';
import { OpenNotificationParams, useList, useNotification, useOne } from '@refinedev/core';
import { useForm } from '@refinedev/mantine';
import { IconCopy } from '@tabler/icons';
import { getPublicClient } from '@wagmi/core';
import { utils } from 'ethers';
import { useEffect, useState } from 'react';
import { createWalletClient, http, parseEther } from 'viem';
import { waitForTransactionReceipt } from 'viem/actions';
import { Address, useAccount, useBalance, useContractWrite, useWalletClient } from 'wagmi';
import { foundry } from 'wagmi/chains';
import { z } from 'zod';

// import { CredbullSDK } from '@credbull/sdk';
// import { ethers } from "ethers";
import { BalanceOf } from '@/components/contracts/balance-of';

import { whitelistAddress } from '@/app/(protected)/dashboard/debug/actions';

declare global {
  interface Window {
    ethereum?: any;
  }
}

const mintSchema = z.object({
  address: z.string().min(42).max(42),
  amount: z.number().positive(),
});

const MintUSDC = ({ erc20Address }: { erc20Address: string }) => {
  const { open } = useNotification();
  const { isConnected, address } = useAccount();
  const { data: client } = useWalletClient();
  const [isLoading, setLoading] = useState(false);

  const form = useForm({
    validate: zodResolver(mintSchema),
    initialValues: { amount: 0, address: '' },
  });

  const { writeAsync } = useContractWrite({
    address: erc20Address as Address,
    abi: SimpleUSDC__factory.abi,
    functionName: 'mint',
    args: [form.values.address as Address, utils.parseUnits((form.values.amount ?? 0).toString(), 'mwei').toBigInt()],
  });

  const onMint = async () => {
    try {
      setLoading(true);
      const mintTx = await writeAsync();
      await waitForTransactionReceipt(client!, mintTx);
      form.reset();
      open?.({ type: 'success', message: 'Mint successful' });
    } catch (e) {
      open?.({ type: 'error', description: 'Mint failed', message: e?.toString() ?? '' });
    } finally {
      setLoading(false);
    }
  };

  const clipboard = useClipboard();

  useEffect(() => {
    if (clipboard.copied) {
      open?.({ type: 'success', message: `USDC address copied!` });
    }
  }, [clipboard.copied, open]);

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Button variant="white" p="0" m="0" onClick={() => clipboard.copy(erc20Address)}>
            <Text size="md" color="black">
              Mint &quot;USDC&quot; <IconCopy size={12} />
            </Text>
          </Button>
          <Text weight={500}></Text>
          <Text size="sm" color="gray">
            <BalanceOf enabled={!!erc20Address && !!address} erc20Address={erc20Address ?? ''} address={address} /> USDC
          </Text>
        </Group>

        <form onSubmit={form.onSubmit(() => onMint())} style={{ marginTop: 'auto' }}>
          <TextInput label="Address" {...form.getInputProps('address')} disabled={!isConnected || isLoading} />
          <NumberInput label="Amount" {...form.getInputProps('amount')} disabled={!isConnected || isLoading} />

          <Group grow>
            <Button
              type="submit"
              variant="light"
              color="blue"
              mt="md"
              radius="md"
              disabled={!isConnected || isLoading}
              loading={isLoading}
            >
              Mint
            </Button>
          </Group>
        </form>
      </Flex>
    </Card>
  );
};

const MintCToken = ({ erc20Address }: { erc20Address: string }) => {
  const { open } = useNotification();
  const { isConnected, address } = useAccount();
  const { data: client } = useWalletClient();
  const [isLoading, setLoading] = useState(false);

  const form = useForm({
    validate: zodResolver(mintSchema),
    initialValues: { amount: 0, address: '' },
  });

  const { writeAsync } = useContractWrite({
    address: erc20Address as Address,
    abi: SimpleToken__factory.abi,
    functionName: 'mint',
    args: [form.values.address as Address, utils.parseUnits((form.values.amount ?? 0).toString(), 18).toBigInt()],
  });

  const onMint = async () => {
    try {
      setLoading(true);
      const mintTx = await writeAsync();
      await waitForTransactionReceipt(client!, mintTx);
      form.reset();
      open?.({ type: 'success', message: 'Mint successful' });
    } catch (e) {
      open?.({ type: 'error', description: 'Mint failed', message: e?.toString() ?? '' });
    } finally {
      setLoading(false);
    }
  };

  const clipboard = useClipboard();

  useEffect(() => {
    if (clipboard.copied) {
      open?.({ type: 'success', message: `cToken address copied!` });
    }
  }, [clipboard.copied, open]);

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Button variant="white" p="0" m="0" onClick={() => clipboard.copy(erc20Address)}>
            <Text size="md" color="black">
              Mint &quot;cToken&quot; <IconCopy size={12} />
            </Text>
          </Button>
          <Text size="sm" color="gray">
            <BalanceOf
              unit={18}
              enabled={!!erc20Address && !!address}
              erc20Address={erc20Address ?? ''}
              address={address}
            />{' '}
            cToken
          </Text>
        </Group>

        <form onSubmit={form.onSubmit(() => onMint())} style={{ marginTop: 'auto' }}>
          <TextInput label="Address" {...form.getInputProps('address')} disabled={!isConnected || isLoading} />
          <NumberInput label="Amount" {...form.getInputProps('amount')} disabled={!isConnected || isLoading} />

          <Group grow>
            <Button
              type="submit"
              variant="light"
              color="blue"
              mt="md"
              radius="md"
              disabled={!isConnected || isLoading}
              loading={isLoading}
            >
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
  const { open } = useNotification();
  const { isConnected, address } = useAccount();
  const { data: ethBalance } = useBalance({ address, watch: true });
  const [isLoading, setLoading] = useState(false);

  const sendETH = async () => {
    setLoading(true);
    try {
      const hash = await localWalletClient.sendTransaction({
        chain: foundry,
        account: FAUCET_ADDRESS,
        to: address,
        value: parseEther('10'),
      });

      const publicClient = getPublicClient();
      await publicClient.waitForTransactionReceipt({ hash });
      open?.({ type: 'success', message: 'Send ETH successful' });
    } catch (e) {
      open?.({ type: 'error', description: 'Send Eth failed', message: e?.toString() ?? '' });
    } finally {
      setTimeout(() => setLoading(false), 1000);
    }
  };

  const balance = parseFloat(ethBalance?.formatted ?? '0');
  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Text weight={500}>Send ETH</Text>
          <Text size="sm" color="gray">
            {balance.toFixed(ethBalance?.formatted.includes('.') ? 3 : 0)} ETH
          </Text>
        </Group>

        <Group position="apart" grow mt="auto">
          <Button
            onClick={() => sendETH()}
            variant="light"
            color="blue"
            mt="md"
            radius="md"
            disabled={!isConnected || isLoading}
            loading={isLoading}
          >
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

const VaultDeposit = ({ erc20Address, mockTokenAddress }: { erc20Address: string; mockTokenAddress: string }) => {
  const { open } = useNotification();
  const { isConnected, address } = useAccount();
  const { data: client } = useWalletClient();
  const [isLoading, setLoading] = useState(false);

  const form = useForm({
    validate: zodResolver(depositSchema),
    initialValues: { amount: 0, address: '' },
  });

  const { writeAsync: approveTokenAsync } = useContractWrite({
    address: mockTokenAddress as Address,
    abi: ERC4626__factory.abi,
    functionName: 'approve',
    args: [form.values.address as Address, utils.parseUnits((form.values.amount ?? 0).toString(), 18).toBigInt()],
  });

  const { writeAsync: approveAsync } = useContractWrite({
    address: erc20Address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'approve',
    args: [form.values.address as Address, utils.parseUnits((form.values.amount ?? 0).toString(), 'mwei').toBigInt()],
  });

  const { writeAsync: depositAsync } = useContractWrite({
    address: form.values.address as Address,
    abi: ERC4626__factory.abi,
    functionName: 'deposit',
    args: [utils.parseUnits((form.values.amount ?? 0).toString(), 'mwei').toBigInt(), address as Address],
  });

  const onDeposit = async () => {
    setLoading(true);
    try {
      const approveTokenTx = await approveTokenAsync();
      await waitForTransactionReceipt(client!, approveTokenTx);

      const approveTx = await approveAsync();

      if (client && approveTx.hash) {
        await waitForTransactionReceipt(client!, approveTx);
        const depositTx = await depositAsync();
        await waitForTransactionReceipt(client!, depositTx);
        form.reset();
      }
      open?.({ type: 'success', message: 'Deposit successful' });
    } catch (e) {
      open?.({ type: 'error', description: 'Deposit failed', message: e?.toString() ?? '' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Text weight={500}>Deposit Closed Vault</Text>
          <Text size="sm" color="gray">
            <BalanceOf
              enabled={!!form.values.address && !!address}
              erc20Address={form.values.address ?? ''}
              address={address}
            />{' '}
            SHARES
          </Text>
        </Group>

        <form onSubmit={form.onSubmit(() => onDeposit())} style={{ marginTop: 'auto' }}>
          <TextInput label="Address" {...form.getInputProps('address')} disabled={!isConnected || isLoading} />
          <NumberInput label="Amount" {...form.getInputProps('amount')} disabled={!isConnected || isLoading} />

          <Group grow>
            <Button
              type="submit"
              variant="light"
              color="blue"
              mt="md"
              radius="md"
              disabled={!isConnected || isLoading}
              loading={isLoading}
            >
              Deposit
            </Button>
          </Group>
        </form>
      </Flex>
    </Card>
  );
};

const WhitelistWalletAddress = () => {
  const { open } = useNotification();
  const { isConnected, address } = useAccount();
  const [isLoading, setLoading] = useState(false);

  const whitelist = async () => {
    setLoading(true);
    try {
      const res = await whitelistAddress(address!);

      const notification: OpenNotificationParams = res
        ? { type: 'success', message: 'Address whitelisted' }
        : { type: 'error', message: 'Whitelist failed' };

      open?.(notification);
    } catch (e) {
      open?.({ type: 'error', description: 'Whitelist failed', message: e?.toString() ?? '' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Text weight={500}>Whitelist address</Text>
        </Group>

        <Group grow mt="auto">
          <Button
            onClick={() => whitelist()}
            variant="light"
            color="blue"
            mt="md"
            radius="md"
            disabled={!isConnected || isLoading}
            loading={isLoading}
          >
            Whitelist
          </Button>
        </Group>
      </Flex>
    </Card>
  );
};

export function Debug(props: { mockTokenAddress: string | undefined }) {
  const { data: list, isLoading } = useList<Tables<'vaults'>>({
    resource: 'vaults',
    pagination: { pageSize: 1 },
  });

  const erc20Address = list?.data[0]?.asset_address;

  return isLoading ? (
    <>Loading...</>
  ) : (
    <Flex justify="space-around" direction="column" gap="60px">
      <SimpleGrid cols={4}>
        <MintUSDC erc20Address={erc20Address ?? ''} />
        <MintCToken erc20Address={props.mockTokenAddress ?? ''} />
        <SendEth />
        <VaultDeposit erc20Address={erc20Address ?? ''} mockTokenAddress={props.mockTokenAddress ?? ''} />
        <WhitelistWalletAddress />
        {/* <LinkWallet /> */}
      </SimpleGrid>
    </Flex>
  );
}
