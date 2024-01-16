'use client';

import { Tables } from '@credbull/api';
import { MockStablecoin__factory } from '@credbull/contracts';
import { Button, Card, Flex, Group, NumberInput, Text } from '@mantine/core';
import { zodResolver } from '@mantine/form';
import { useList } from '@refinedev/core';
import { useForm } from '@refinedev/mantine';
import { getPublicClient } from '@wagmi/core';
import { createWalletClient, http, parseEther } from 'viem';
import { Address, useAccount, useBalance, useContractWrite } from 'wagmi';
import { foundry } from 'wagmi/chains';
import { z } from 'zod';

import { BalanceOf } from '@/components/contracts/balance-of';

const schema = z.object({
  amount: z.number().positive(),
});

const FAUCET_ADDRESS = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

const localWalletClient = createWalletClient({
  chain: foundry,
  transport: http(),
});

export function Debug() {
  const { isConnected, address } = useAccount();
  const { data: ethBalance } = useBalance({ address, watch: true });

  const form = useForm({
    validate: zodResolver(schema),
    initialValues: {
      amount: 0,
    },
  });

  const { data: list, isLoading } = useList<Tables<'vaults'>>({
    resource: 'vaults',
    pagination: { pageSize: 1 },
  });

  const erc20Address = list?.data[0].asset_address;

  const { writeAsync } = useContractWrite({
    address: erc20Address as Address,
    abi: MockStablecoin__factory.abi,
    functionName: 'mint',
    args: [address as Address, parseEther((form.values.amount ?? 0).toString())],
  });

  const onMint = async () => {
    await writeAsync();
  };

  const sendETH = async () => {
    try {
      const transactionHash = await localWalletClient.sendTransaction({
        chain: foundry,
        account: FAUCET_ADDRESS,
        to: address,
        value: parseEther('10'),
      });

      const publicClient = getPublicClient();
      await publicClient.waitForTransactionReceipt({
        hash: transactionHash,
        confirmations: 2,
      });
    } catch (error) {
      console.error('⚡️ ~ file: FaucetButton.tsx:sendETH ~ error', error);
    }
  };

  return isLoading ? (
    <>Loading...</>
  ) : (
    <Flex justify="space-around" direction="column" gap="60px">
      <Flex justify="center" gap="30px">
        <Card shadow="sm" p="xl" radius="md" withBorder>
          <Group position="apart" mt="md" mb="xs">
            <Text weight={500}>Mint &quot;USDC&quot;</Text>
          </Group>

          <Group position="apart" mt="md" mb="xs">
            <Text size="sm" color="gray">
              Total Balance
            </Text>
            <Text size="sm" color="gray">
              <BalanceOf enabled={!!erc20Address && !!address} erc20Address={erc20Address ?? ''} address={address} />{' '}
              USDC
            </Text>
          </Group>

          <form onSubmit={form.onSubmit(() => onMint())}>
            <Group mt="xl">
              <NumberInput label="Amount" {...form.getInputProps('amount')} disabled={!isConnected} />

              <Button type="submit" variant="light" color="blue" mt="md" radius="md" disabled={!isConnected}>
                Mint
              </Button>
            </Group>
          </form>
        </Card>
        <Card shadow="sm" p="xl" radius="md" withBorder>
          <Group position="apart" mt="md" mb="xs">
            <Text weight={500}>Send ETH</Text>
          </Group>

          <Group position="apart" mt="md" mb="xs">
            <Text size="sm" color="gray">
              Total Balance
            </Text>
            <Text size="sm" color="gray">
              {ethBalance?.formatted} ETH
            </Text>
          </Group>

          <Group mt="xl" position="apart" grow>
            <Button onClick={() => sendETH()} variant="light" color="blue" mt="md" radius="md" disabled={!isConnected}>
              Send
            </Button>
          </Group>
        </Card>
      </Flex>
    </Flex>
  );
}
