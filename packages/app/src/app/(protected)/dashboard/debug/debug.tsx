'use client';

import { Tables } from '@credbull/api';
import { ERC4626__factory, MockStablecoin__factory } from '@credbull/contracts';
import { CredbullVaultFactory__factory } from '@credbull/contracts';
import Deployments from '@credbull/contracts/deployments/index.json';
import { Button, Card, Flex, Group, NumberInput, SimpleGrid, Text, TextInput } from '@mantine/core';
import { zodResolver } from '@mantine/form';
import { useList, useNotification } from '@refinedev/core';
import { OpenNotificationParams } from '@refinedev/core/dist/contexts/notification/INotificationContext';
import { useForm } from '@refinedev/mantine';
import { getPublicClient } from '@wagmi/core';
import { ethers } from 'ethers';
import { useState } from 'react';
import { createWalletClient, http, parseEther } from 'viem';
import { waitForTransactionReceipt } from 'viem/actions';
import { Address, useAccount, useBalance, useContractRead, useContractWrite, useNetwork, useWalletClient } from 'wagmi';
import { foundry } from 'wagmi/chains';
import { z } from 'zod';

import { BalanceOf } from '@/components/contracts/balance-of';

import { whitelistAddress } from '@/app/(protected)/dashboard/debug/actions';

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
    abi: MockStablecoin__factory.abi,
    functionName: 'mint',
    args: [form.values.address as Address, parseEther((form.values.amount ?? 0).toString())],
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

  return (
    <Card shadow="sm" p="xl" radius="md" withBorder>
      <Flex direction="column" h="100%">
        <Group position="apart" mt="md" mb="xs">
          <Text weight={500}>Mint &quot;USDC&quot;</Text>
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

const VaultDeposit = ({ erc20Address }: { erc20Address: string }) => {
  const { open } = useNotification();
  const { isConnected, address } = useAccount();
  const { data: client } = useWalletClient();
  const [isLoading, setLoading] = useState(false);

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
    setLoading(true);
    try {
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

const CreateVaultFromFactory = () => {
  const { open } = useNotification();
  const { isConnected, address } = useAccount();
  const { data: client } = useWalletClient();
  const { chain } = useNetwork();
  const [isLoading, setLoading] = useState(false);
  const chainId = chain ? chain.id.toString() : '31337';
  const deploymentData = Deployments[chainId as '31337'];
  const factoryContractAddress = deploymentData.CredbullVaultFactory[0].address;

  const form = useForm({
    initialValues: {
      owner: deploymentData.CredbullVaultFactory[0].arguments[0],
      asset: deploymentData.MockStablecoin[0].address,
      shareName: 'Test share',
      shareSymbol: 'Test symbol',
      openAt: 1705276800,
      closesAt: 1705286800,
      custodian: deploymentData.CredbullEntities[0].arguments[0],
      kycProvider: deploymentData.CredbullEntities[0].arguments[1],
      treasury: deploymentData.CredbullEntities[0].arguments[2],
      activityReward: deploymentData.CredbullEntities[0].arguments[3],
    },
  });

  const { writeAsync: createVaultAsync } = useContractWrite({
    address: factoryContractAddress as Address,
    abi: CredbullVaultFactory__factory.abi,
    functionName: 'createVault',
    args: [
      {
        owner: form.values.owner as Address,
        asset: form.values.asset as Address,
        shareName: form.values.shareName,
        shareSymbol: form.values.shareSymbol,
        depositOpensAt: BigInt(form.values.openAt),
        depositClosesAt: BigInt(form.values.closesAt),
        redemptionOpensAt: BigInt(form.values.openAt),
        redemptionClosesAt: BigInt(form.values.closesAt),
        custodian: form.values.custodian as Address,
        kycProvider: form.values.kycProvider as Address,
        treasury: form.values.treasury as Address,
        activityReward: form.values.activityReward as Address,
        promisedYield: BigInt(10),
      },
    ],
  });

  const createVault = async () => {
    setLoading(true);
    try {
      await createVaultAsync();
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
          <Text weight={500}>Create vault</Text>
        </Group>

        <form onSubmit={form.onSubmit(() => createVault())} style={{ marginTop: 'auto' }}>
          <TextInput label="Owner" {...form.getInputProps('owner')} disabled={!isConnected || isLoading} />
          <TextInput label="Asset" {...form.getInputProps('asset')} disabled={!isConnected || isLoading} />
          <TextInput label="Share name" {...form.getInputProps('shareName')} disabled={!isConnected || isLoading} />
          <TextInput label="Share symbol" {...form.getInputProps('shareSymbol')} disabled={!isConnected || isLoading} />
          <TextInput label="Opens At" {...form.getInputProps('openAt')} disabled={!isConnected || isLoading} />
          <TextInput label="Closes At" {...form.getInputProps('closesAt')} disabled={!isConnected || isLoading} />
          <TextInput label="Custodian" {...form.getInputProps('custodian')} disabled={!isConnected || isLoading} />
          <TextInput label="Kyc Provider" {...form.getInputProps('kycProvider')} disabled={!isConnected || isLoading} />
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
              Create Vault
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

  const erc20Address = list?.data[0]?.asset_address;

  return isLoading ? (
    <>Loading...</>
  ) : (
    <Flex justify="space-around" direction="column" gap="60px">
      <SimpleGrid cols={4}>
        <MintUSDC erc20Address={erc20Address ?? ''} />
        <SendEth />
        <VaultDeposit erc20Address={erc20Address ?? ''} />
        <WhitelistWalletAddress />
      </SimpleGrid>

      <SimpleGrid cols={1}>
        <CreateVaultFromFactory />
      </SimpleGrid>
    </Flex>
  );
}
