import {connectorsForWallets} from "@rainbow-me/rainbowkit";
import {
  coinbaseWallet,
  ledgerWallet,
  metaMaskWallet,
  rainbowWallet,
  safeWallet,
  walletConnectWallet,
} from "@rainbow-me/rainbowkit/wallets";
import {rainbowkitBurnerWallet} from "burner-connector";
import * as chains from "viem/chains";
import scaffoldConfig from "~~/scaffold.config";

const appName = "liquid-spike-ui";
const { onlyLocalBurnerWallet, targetNetworks, walletConnectProjectId } = scaffoldConfig;

const includeBurner =
  !targetNetworks.some(network => network.id !== (chains.hardhat as chains.Chain).id) || !onlyLocalBurnerWallet;

export const wagmiConnectors = connectorsForWallets(
  [
    {
      groupName: "Supported Wallets",
      wallets: [
        () => metaMaskWallet({ projectId: walletConnectProjectId }),
        () => walletConnectWallet({ projectId: walletConnectProjectId }),
        () => ledgerWallet({ projectId: walletConnectProjectId }),
        () => coinbaseWallet({ appName: appName }),
        () => rainbowWallet({ projectId: walletConnectProjectId }),
        () => safeWallet(),
        ...(includeBurner ? [() => rainbowkitBurnerWallet() as unknown as ReturnType<typeof metaMaskWallet>] : []),
      ],
    },
  ],
  {
    appName,
    projectId: walletConnectProjectId,
  },
);
