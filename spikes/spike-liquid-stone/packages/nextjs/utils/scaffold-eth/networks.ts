import { Network } from "alchemy-sdk";
import * as chains from "viem/chains";
import scaffoldConfig, { plume, plumeTestnet } from "~~/scaffold.config";
import {
  ChainAddresses,
  plumeMainnetSafe,
  primvevaultCredbullDefi,
  testnetCredbullDevops,
} from "~~/utils/scaffold-eth/chainAddresses";
import {Chain} from "viem";
import {ethers} from "ethers";

type ChainAttributes = {
  // color | [lightThemeColor, darkThemeColor]
  color: string | [string, string];
  // Used to fetch price by providing mainnet token address
  // for networks having native currency other than ETH
  nativeCurrencyTokenAddress?: string;

  // alchemy Api's Network
  alchemyApiNetwork?: Network;

  // Chain well-known addresses
  addresses?: ChainAddresses;
};

export type ChainWithAttributes = chains.Chain & Partial<ChainAttributes>;

// Mapping of chainId to RPC chain name an format followed by alchemy and infura
export const RPC_CHAIN_NAMES: Record<number, string> = {
  [chains.mainnet.id]: "eth-mainnet",
  [chains.goerli.id]: "eth-goerli",
  [chains.sepolia.id]: "eth-sepolia",
  [chains.optimism.id]: "opt-mainnet",
  [chains.optimismGoerli.id]: "opt-goerli",
  [chains.optimismSepolia.id]: "opt-sepolia",
  [chains.arbitrum.id]: "arb-mainnet",
  [chains.arbitrumGoerli.id]: "arb-goerli",
  [chains.arbitrumSepolia.id]: "arb-sepolia",
  [chains.polygon.id]: "polygon-mainnet",
  [chains.polygonMumbai.id]: "polygon-mumbai",
  [chains.polygonAmoy.id]: "polygon-amoy",
  [chains.astar.id]: "astar-mainnet",
  [chains.polygonZkEvm.id]: "polygonzkevm-mainnet",
  [chains.polygonZkEvmTestnet.id]: "polygonzkevm-testnet",
  [chains.base.id]: "base-mainnet",
  [chains.baseGoerli.id]: "base-goerli",
  [chains.baseSepolia.id]: "base-sepolia",
};

export const getAlchemyHttpUrl = (chainId: number) => {
  return RPC_CHAIN_NAMES[chainId]
    ? `https://${RPC_CHAIN_NAMES[chainId]}.g.alchemy.com/v2/${scaffoldConfig.alchemyApiKey}`
    : undefined;
};

export const NETWORKS_EXTRA_DATA: Record<string, ChainAttributes> = {
  [chains.hardhat.id]: {
    color: "#b8af0c",
    addresses: testnetCredbullDevops,
  },
  [chains.mainnet.id]: {
    color: "#1b550a",
    alchemyApiNetwork: Network.ETH_MAINNET,
    addresses: primvevaultCredbullDefi,
  },
  [chains.sepolia.id]: {
    color: "#2c910f",
    alchemyApiNetwork: Network.ETH_SEPOLIA,
    addresses: testnetCredbullDevops,
  },
  [chains.polygon.id]: {
    color: "#762bf7",
    alchemyApiNetwork: Network.MATIC_MAINNET,
    addresses: primvevaultCredbullDefi,
    nativeCurrencyTokenAddress: "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0",
  },
  [chains.polygonAmoy.id]: {
    color: "#9b2bf7",
    alchemyApiNetwork: Network.MATIC_AMOY,
    addresses: testnetCredbullDevops,
    nativeCurrencyTokenAddress: "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0",
  },
  [chains.arbitrum.id]: {
    color: "#095077",
    addresses: primvevaultCredbullDefi,
    alchemyApiNetwork: Network.ARB_MAINNET,
  },
  [chains.arbitrumSepolia.id]: {
    color: "#28a0f0",
    alchemyApiNetwork: Network.ARB_SEPOLIA,
    addresses: testnetCredbullDevops,
  },
  [plume.id]: {
    color: "#ff6b81",
    addresses: plumeMainnetSafe,
  },
  [plumeTestnet.id]: {
    color: "#ff94a1",
    addresses: testnetCredbullDevops,
  },
};

/**
 * Gives the block explorer transaction URL, returns empty string if the network is a local chain
 */
export function getBlockExplorerTxLink(chainId: number, txnHash: string) {
  const chainNames = Object.keys(chains);

  const targetChainArr = chainNames.filter(chainName => {
    const wagmiChain = chains[chainName as keyof typeof chains];
    return wagmiChain.id === chainId;
  });

  if (targetChainArr.length === 0) {
    return "";
  }

  const targetChain = targetChainArr[0] as keyof typeof chains;
  const blockExplorerTxURL = chains[targetChain]?.blockExplorers?.default?.url;

  if (!blockExplorerTxURL) {
    return "";
  }

  return `${blockExplorerTxURL}/tx/${txnHash}`;
}

/**
 * Gives the block explorer URL for a given address.
 * Defaults to Etherscan if no (wagmi) block explorer is configured for the network.
 */
export function getBlockExplorerAddressLink(network: chains.Chain, address: string) {
  const blockExplorerBaseURL = network.blockExplorers?.default?.url;
  if (network.id === chains.hardhat.id) {
    return `/blockexplorer/address/${address}`;
  }

  if (!blockExplorerBaseURL) {
    return `https://etherscan.io/address/${address}`;
  }

  return `${blockExplorerBaseURL}/address/${address}`;
}

/**
 * @returns targetNetworks array containing networks configured in scaffold.config including extra network metadata
 */
export function getTargetNetworks(): ChainWithAttributes[] {
  return scaffoldConfig.targetNetworks.map(targetNetwork => ({
    ...targetNetwork,
    ...NETWORKS_EXTRA_DATA[targetNetwork.id],
  }));
}

export function getTargetNetworkById(chainId: number | undefined): ChainWithAttributes | undefined {
  return getTargetNetworks().find(network => network.id === chainId);
}

export async function getProvider(chain: Chain) {
  const rpcUrl = getAlchemyHttpUrl(chain.id) || chain?.rpcUrls?.default?.http[0];

  return new ethers.JsonRpcProvider(rpcUrl);
}
