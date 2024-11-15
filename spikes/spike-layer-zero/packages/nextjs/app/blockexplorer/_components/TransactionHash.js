"use strict";
"use client";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TransactionHash = void 0;
const react_1 = require("react");
const link_1 = __importDefault(require("next/link"));
const react_copy_to_clipboard_1 = require("react-copy-to-clipboard");
const outline_1 = require("@heroicons/react/24/outline");
const TransactionHash = ({ hash }) => {
    const [addressCopied, setAddressCopied] = (0, react_1.useState)(false);
    return (<div className="flex items-center">
      <link_1.default href={`/blockexplorer/transaction/${hash}`}>
        {hash === null || hash === void 0 ? void 0 : hash.substring(0, 6)}...{hash === null || hash === void 0 ? void 0 : hash.substring(hash.length - 4)}
      </link_1.default>
      {addressCopied ? (<outline_1.CheckCircleIcon className="ml-1.5 text-xl font-normal text-sky-600 h-5 w-5 cursor-pointer" aria-hidden="true"/>) : (<react_copy_to_clipboard_1.CopyToClipboard text={hash} onCopy={() => {
                setAddressCopied(true);
                setTimeout(() => {
                    setAddressCopied(false);
                }, 800);
            }}>
          <outline_1.DocumentDuplicateIcon className="ml-1.5 text-xl font-normal text-sky-600 h-5 w-5 cursor-pointer" aria-hidden="true"/>
        </react_copy_to_clipboard_1.CopyToClipboard>)}
    </div>);
};
exports.TransactionHash = TransactionHash;
