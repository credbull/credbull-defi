'use client';

import { Tables } from '@/types/supabase';
import { Flex } from '@mantine/core';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useList } from '@refinedev/core';
import { useTransition } from 'react';
import { SiweMessage, generateNonce } from 'siwe';
import { useAccount, useSignMessage } from 'wagmi';

import { linkWallet } from '@/app/(protected)/dashboard/link-wallet.action';

export function LinkWallet() {
  const { refetch } = useList<Tables<'user_wallets'>>({ resource: 'user_wallets' });

  const { signMessageAsync } = useSignMessage();
  const [isPending, startTransition] = useTransition();

  useAccount({
    onConnect: async ({ address, connector, isReconnected }) => {
      if (isReconnected) return;

      const { data } = await refetch();

      if (data?.data.find((wallet) => wallet.address === address)) return;

      const preMessage = new SiweMessage({
        domain: window.location.host,
        address,
        statement: 'By connecting your wallet, you agree to the Terms of Service and Privacy Policy.',
        uri: window.location.origin,
        version: '1',
        chainId: await connector?.getChainId(),
        nonce: generateNonce(),
      });

      const message = preMessage.prepareMessage();
      const signature = await signMessageAsync({ message });
      startTransition(() => linkWallet(message, signature));
    },
  });

  return <Flex justify="flex-end">{isPending ? <>Linking...</> : <ConnectButton />}</Flex>;
}
