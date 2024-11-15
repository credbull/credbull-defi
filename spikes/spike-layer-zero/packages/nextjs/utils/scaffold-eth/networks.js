"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.NETWORKS_EXTRA_DATA = exports.getAlchemyHttpUrl = exports.RPC_CHAIN_NAMES = void 0;
exports.getBlockExplorerTxLink = getBlockExplorerTxLink;
exports.getBlockExplorerAddressLink = getBlockExplorerAddressLink;
exports.getTargetNetworks = getTargetNetworks;
const chains = __importStar(require("viem/chains"));
const scaffold_config_1 = __importDefault(require("~~/scaffold.config"));
// Mapping of chainId to RPC chain name an format followed by alchemy and infura
exports.RPC_CHAIN_NAMES = {
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
const getAlchemyHttpUrl = (chainId) => {
    return exports.RPC_CHAIN_NAMES[chainId]
        ? `https://${exports.RPC_CHAIN_NAMES[chainId]}.g.alchemy.com/v2/${scaffold_config_1.default.alchemyApiKey}`
        : undefined;
};
exports.getAlchemyHttpUrl = getAlchemyHttpUrl;
exports.NETWORKS_EXTRA_DATA = {
    [chains.hardhat.id]: {
        color: "#b8af0c",
    },
    [chains.mainnet.id]: {
        color: "#ff8b9e",
    },
    [chains.sepolia.id]: {
        color: ["#5f4bb6", "#87ff65"],
    },
    [chains.gnosis.id]: {
        color: "#48a9a6",
    },
    [chains.polygon.id]: {
        color: "#2bbdf7",
        nativeCurrencyTokenAddress: "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0",
    },
    [chains.polygonMumbai.id]: {
        color: "#92D9FA",
        nativeCurrencyTokenAddress: "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0",
    },
    [chains.optimismSepolia.id]: {
        color: "#f01a37",
    },
    [chains.optimism.id]: {
        color: "#f01a37",
    },
    [chains.arbitrumSepolia.id]: {
        color: "#28a0f0",
    },
    [chains.arbitrum.id]: {
        color: "#28a0f0",
    },
    [chains.fantom.id]: {
        color: "#1969ff",
    },
    [chains.fantomTestnet.id]: {
        color: "#1969ff",
    },
    [chains.scrollSepolia.id]: {
        color: "#fbebd4",
    },
};
/**
 * Gives the block explorer transaction URL, returns empty string if the network is a local chain
 */
function getBlockExplorerTxLink(chainId, txnHash) {
    var _a, _b, _c;
    const chainNames = Object.keys(chains);
    const targetChainArr = chainNames.filter(chainName => {
        const wagmiChain = chains[chainName];
        return wagmiChain.id === chainId;
    });
    if (targetChainArr.length === 0) {
        return "";
    }
    const targetChain = targetChainArr[0];
    const blockExplorerTxURL = (_c = (_b = (_a = chains[targetChain]) === null || _a === void 0 ? void 0 : _a.blockExplorers) === null || _b === void 0 ? void 0 : _b.default) === null || _c === void 0 ? void 0 : _c.url;
    if (!blockExplorerTxURL) {
        return "";
    }
    return `${blockExplorerTxURL}/tx/${txnHash}`;
}
/**
 * Gives the block explorer URL for a given address.
 * Defaults to Etherscan if no (wagmi) block explorer is configured for the network.
 */
function getBlockExplorerAddressLink(network, address) {
    var _a, _b;
    const blockExplorerBaseURL = (_b = (_a = network.blockExplorers) === null || _a === void 0 ? void 0 : _a.default) === null || _b === void 0 ? void 0 : _b.url;
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
function getTargetNetworks() {
    return scaffold_config_1.default.targetNetworks.map(targetNetwork => (Object.assign(Object.assign({}, targetNetwork), exports.NETWORKS_EXTRA_DATA[targetNetwork.id])));
}
