import { Chain } from "viem";
import * as chains from "viem/chains";
import * as dotenv from 'dotenv';

dotenv.config();

console.log(`*** Config loaded, network is ${process.env.NEXT_PUBLIC_NETWORK}`);

export const plume: Chain = {
  id: 98865,
  name: "Plume",
  nativeCurrency: { name: "Plume Ethereum", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["https://phoenix-rpc.plumenetwork.xyz/"] },
    public: { http: ["https://phoenix-rpc.plumenetwork.xyz/"] },
  },
  formatters: undefined,
  fees: undefined,
  blockExplorers: {
    default: { name: "Plume Explorer", url: "https://phoenix-explorer.plumenetwork.xyz" },
  },
  testnet: true,
} as Chain;

export const plumeTestnet: Chain = {
  id: 98864,
  name: "Plume Testnet",
  nativeCurrency: { name: "Plume Ethereum", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["https://test-rpc.plumenetwork.xyz"] },
    public: { http: ["https://test-rpc.plumenetwork.xyz"] },
  },
  formatters: undefined,
  fees: undefined,
  blockExplorers: {
    default: { name: "Plume Explorer", url: "https://test-explorer.plumenetwork.xyz" },
  },
  testnet: true,
} as Chain;

export type ScaffoldConfig = {
  targetNetworks: readonly chains.Chain[];
  pollingInterval: number;
  alchemyApiKey: string;
  walletConnectProjectId: string;
  onlyLocalBurnerWallet: boolean;
};

const scaffoldConfig = {
  // The networks on which your DApp is live
  targetNetworks: [chains.arbitrumSepolia, plumeTestnet, plume, chains.polygonAmoy, chains.polygon, chains.foundry],

  // The interval at which your front-end polls the RPC servers for new data
  // it has no effect if you only target the local network (default is 4000)
  pollingInterval: 30000,

  // This is ours Alchemy's default API key.
  // You can get your own at https://dashboard.alchemyapi.io
  // It's recommended to store it in an env variable:
  // .env.local for local testing, and in the Vercel/system env config for live apps.
  alchemyApiKey: process.env.NEXT_PUBLIC_ALCHEMY_API_KEY || "oKxs-03sij-U_N0iOlrSsZFr29-IqbuF",

  // This is ours WalletConnect's default project ID.
  // You can get your own at https://cloud.walletconnect.com
  // It's recommended to store it in an env variable:
  // .env.local for local testing, and in the Vercel/system env config for live apps.
  walletConnectProjectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || "3a8170812b534d0ff9d794f19a901d64",

  // Only show the Burner Wallet when running on hardhat network
  onlyLocalBurnerWallet: true,
} as const satisfies ScaffoldConfig;

export default scaffoldConfig;
