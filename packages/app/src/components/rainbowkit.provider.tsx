'use client';

import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit';
import { ReactNode } from 'react';
import { WagmiProvider } from 'wagmi';
import { foundry, polygonMumbai } from 'wagmi/chains';

const wagmiConfig = getDefaultConfig({
  appName: 'Credbull DeFI',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID,
  chains: [foundry, polygonMumbai],
});

export function RainbowkitProvider({ children }: { children: ReactNode }) {
  return (
    <WagmiProvider config={wagmiConfig}>
      <RainbowKitProvider>{children}</RainbowKitProvider>
    </WagmiProvider>
  );
}
