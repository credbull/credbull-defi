"use strict";
"use client";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Address = void 0;
const react_1 = require("react");
const link_1 = __importDefault(require("next/link"));
const react_copy_to_clipboard_1 = require("react-copy-to-clipboard");
const viem_1 = require("viem");
const chains_1 = require("viem/chains");
const ens_1 = require("viem/ens");
const wagmi_1 = require("wagmi");
const outline_1 = require("@heroicons/react/24/outline");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const useTargetNetwork_1 = require("~~/hooks/scaffold-eth/useTargetNetwork");
const scaffold_eth_2 = require("~~/utils/scaffold-eth");
const blockieSizeMap = {
    xs: 6,
    sm: 7,
    base: 8,
    lg: 9,
    xl: 10,
    "2xl": 12,
    "3xl": 15,
};
/**
 * Displays an address (or ENS) with a Blockie image and option to copy address.
 */
const Address = ({ address, disableAddressLink, format, size = "base" }) => {
    const [ens, setEns] = (0, react_1.useState)();
    const [ensAvatar, setEnsAvatar] = (0, react_1.useState)();
    const [addressCopied, setAddressCopied] = (0, react_1.useState)(false);
    const checkSumAddress = address ? (0, viem_1.getAddress)(address) : undefined;
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const { data: fetchedEns } = (0, wagmi_1.useEnsName)({
        address: checkSumAddress,
        chainId: 1,
        query: {
            enabled: (0, viem_1.isAddress)(checkSumAddress !== null && checkSumAddress !== void 0 ? checkSumAddress : ""),
        },
    });
    const { data: fetchedEnsAvatar } = (0, wagmi_1.useEnsAvatar)({
        name: fetchedEns ? (0, ens_1.normalize)(fetchedEns) : undefined,
        chainId: 1,
        query: {
            enabled: Boolean(fetchedEns),
            gcTime: 30000,
        },
    });
    // We need to apply this pattern to avoid Hydration errors.
    (0, react_1.useEffect)(() => {
        setEns(fetchedEns);
    }, [fetchedEns]);
    (0, react_1.useEffect)(() => {
        setEnsAvatar(fetchedEnsAvatar);
    }, [fetchedEnsAvatar]);
    // Skeleton UI
    if (!checkSumAddress) {
        return (<div className="animate-pulse flex space-x-4">
        <div className="rounded-md bg-slate-300 h-6 w-6"></div>
        <div className="flex items-center space-y-6">
          <div className="h-2 w-28 bg-slate-300 rounded"></div>
        </div>
      </div>);
    }
    if (!(0, viem_1.isAddress)(checkSumAddress)) {
        return <span className="text-error">Wrong address</span>;
    }
    const blockExplorerAddressLink = (0, scaffold_eth_2.getBlockExplorerAddressLink)(targetNetwork, checkSumAddress);
    let displayAddress = (checkSumAddress === null || checkSumAddress === void 0 ? void 0 : checkSumAddress.slice(0, 6)) + "..." + (checkSumAddress === null || checkSumAddress === void 0 ? void 0 : checkSumAddress.slice(-4));
    if (ens) {
        displayAddress = ens;
    }
    else if (format === "long") {
        displayAddress = checkSumAddress;
    }
    return (<div className="flex items-center flex-shrink-0">
      <div className="flex-shrink-0">
        <scaffold_eth_1.BlockieAvatar address={checkSumAddress} ensImage={ensAvatar} size={(blockieSizeMap[size] * 24) / blockieSizeMap["base"]}/>
      </div>
      {disableAddressLink ? (<span className={`ml-1.5 text-${size} font-normal`}>{displayAddress}</span>) : targetNetwork.id === chains_1.hardhat.id ? (<span className={`ml-1.5 text-${size} font-normal`}>
          <link_1.default href={blockExplorerAddressLink}>{displayAddress}</link_1.default>
        </span>) : (<a className={`ml-1.5 text-${size} font-normal`} target="_blank" href={blockExplorerAddressLink} rel="noopener noreferrer">
          {displayAddress}
        </a>)}
      {addressCopied ? (<outline_1.CheckCircleIcon className="ml-1.5 text-xl font-normal text-sky-600 h-5 w-5 cursor-pointer flex-shrink-0" aria-hidden="true"/>) : (<react_copy_to_clipboard_1.CopyToClipboard text={checkSumAddress} onCopy={() => {
                setAddressCopied(true);
                setTimeout(() => {
                    setAddressCopied(false);
                }, 800);
            }}>
          <outline_1.DocumentDuplicateIcon className="ml-1.5 text-xl font-normal text-sky-600 h-5 w-5 cursor-pointer flex-shrink-0" aria-hidden="true"/>
        </react_copy_to_clipboard_1.CopyToClipboard>)}
    </div>);
};
exports.Address = Address;
