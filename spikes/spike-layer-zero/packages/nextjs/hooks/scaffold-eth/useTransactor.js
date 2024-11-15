"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.useTransactor = void 0;
const core_1 = require("@wagmi/core");
const wagmi_1 = require("wagmi");
const wagmiConfig_1 = require("~~/services/web3/wagmiConfig");
const scaffold_eth_1 = require("~~/utils/scaffold-eth");
/**
 * Custom notification content for TXs.
 */
const TxnNotification = ({ message, blockExplorerLink }) => {
    return (<div className={`flex flex-col ml-1 cursor-default`}>
      <p className="my-0">{message}</p>
      {blockExplorerLink && blockExplorerLink.length > 0 ? (<a href={blockExplorerLink} target="_blank" rel="noreferrer" className="block link text-md">
          check out transaction
        </a>) : null}
    </div>);
};
/**
 * Runs Transaction passed in to returned function showing UI feedback.
 * @param _walletClient - Optional wallet client to use. If not provided, will use the one from useWalletClient.
 * @returns function that takes in transaction function as callback, shows UI feedback for transaction and returns a promise of the transaction hash
 */
const useTransactor = (_walletClient) => {
    let walletClient = _walletClient;
    const { data } = (0, wagmi_1.useWalletClient)();
    if (walletClient === undefined && data) {
        walletClient = data;
    }
    const result = (tx, options) => __awaiter(void 0, void 0, void 0, function* () {
        if (!walletClient) {
            scaffold_eth_1.notification.error("Cannot access account");
            console.error("⚡️ ~ file: useTransactor.tsx ~ error");
            return;
        }
        let notificationId = null;
        let transactionHash = undefined;
        let transactionReceipt;
        let blockExplorerTxURL = "";
        try {
            const network = yield walletClient.getChainId();
            // Get full transaction from public client
            const publicClient = (0, core_1.getPublicClient)(wagmiConfig_1.wagmiConfig);
            notificationId = scaffold_eth_1.notification.loading(<TxnNotification message="Awaiting for user confirmation"/>);
            if (typeof tx === "function") {
                // Tx is already prepared by the caller
                const result = yield tx();
                transactionHash = result;
            }
            else if (tx != null) {
                transactionHash = yield walletClient.sendTransaction(tx);
            }
            else {
                throw new Error("Incorrect transaction passed to transactor");
            }
            scaffold_eth_1.notification.remove(notificationId);
            blockExplorerTxURL = network ? (0, scaffold_eth_1.getBlockExplorerTxLink)(network, transactionHash) : "";
            notificationId = scaffold_eth_1.notification.loading(<TxnNotification message="Waiting for transaction to complete." blockExplorerLink={blockExplorerTxURL}/>);
            transactionReceipt = yield publicClient.waitForTransactionReceipt({
                hash: transactionHash,
                confirmations: options === null || options === void 0 ? void 0 : options.blockConfirmations,
            });
            scaffold_eth_1.notification.remove(notificationId);
            if (transactionReceipt.status === "reverted")
                throw new Error("Transaction reverted");
            scaffold_eth_1.notification.success(<TxnNotification message="Transaction completed successfully!" blockExplorerLink={blockExplorerTxURL}/>, {
                icon: "🎉",
            });
            if (options === null || options === void 0 ? void 0 : options.onBlockConfirmation)
                options.onBlockConfirmation(transactionReceipt);
        }
        catch (error) {
            if (notificationId) {
                scaffold_eth_1.notification.remove(notificationId);
            }
            console.error("⚡️ ~ file: useTransactor.ts ~ error", error);
            const message = (0, scaffold_eth_1.getParsedError)(error);
            // if receipt was reverted, show notification with block explorer link and return error
            if ((transactionReceipt === null || transactionReceipt === void 0 ? void 0 : transactionReceipt.status) === "reverted") {
                scaffold_eth_1.notification.error(<TxnNotification message={message} blockExplorerLink={blockExplorerTxURL}/>);
                throw error;
            }
            scaffold_eth_1.notification.error(message);
            throw error;
        }
        return transactionHash;
    });
    return result;
};
exports.useTransactor = useTransactor;
