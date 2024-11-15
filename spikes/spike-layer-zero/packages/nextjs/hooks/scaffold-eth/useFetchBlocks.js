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
exports.useFetchBlocks = exports.testClient = void 0;
const react_1 = require("react");
const viem_1 = require("viem");
const chains_1 = require("viem/chains");
const scaffold_eth_1 = require("~~/utils/scaffold-eth");
const BLOCKS_PER_PAGE = 20;
exports.testClient = (0, viem_1.createTestClient)({
    chain: chains_1.hardhat,
    mode: "hardhat",
    transport: (0, viem_1.webSocket)("ws://127.0.0.1:8545"),
})
    .extend(viem_1.publicActions)
    .extend(viem_1.walletActions);
const useFetchBlocks = () => {
    const [blocks, setBlocks] = (0, react_1.useState)([]);
    const [transactionReceipts, setTransactionReceipts] = (0, react_1.useState)({});
    const [currentPage, setCurrentPage] = (0, react_1.useState)(0);
    const [totalBlocks, setTotalBlocks] = (0, react_1.useState)(0n);
    const [error, setError] = (0, react_1.useState)(null);
    const fetchBlocks = (0, react_1.useCallback)(() => __awaiter(void 0, void 0, void 0, function* () {
        setError(null);
        try {
            const blockNumber = yield exports.testClient.getBlockNumber();
            setTotalBlocks(blockNumber);
            const startingBlock = blockNumber - BigInt(currentPage * BLOCKS_PER_PAGE);
            const blockNumbersToFetch = Array.from({ length: Number(BLOCKS_PER_PAGE < startingBlock + 1n ? BLOCKS_PER_PAGE : startingBlock + 1n) }, (_, i) => startingBlock - BigInt(i));
            const blocksWithTransactions = blockNumbersToFetch.map((blockNumber) => __awaiter(void 0, void 0, void 0, function* () {
                try {
                    return exports.testClient.getBlock({ blockNumber, includeTransactions: true });
                }
                catch (err) {
                    setError(err instanceof Error ? err : new Error("An error occurred."));
                    throw err;
                }
            }));
            const fetchedBlocks = yield Promise.all(blocksWithTransactions);
            fetchedBlocks.forEach(block => {
                block.transactions.forEach(tx => (0, scaffold_eth_1.decodeTransactionData)(tx));
            });
            const txReceipts = yield Promise.all(fetchedBlocks.flatMap(block => block.transactions.map((tx) => __awaiter(void 0, void 0, void 0, function* () {
                try {
                    const receipt = yield exports.testClient.getTransactionReceipt({ hash: tx.hash });
                    return { [tx.hash]: receipt };
                }
                catch (err) {
                    setError(err instanceof Error ? err : new Error("An error occurred."));
                    throw err;
                }
            }))));
            setBlocks(fetchedBlocks);
            setTransactionReceipts(prevReceipts => (Object.assign(Object.assign({}, prevReceipts), Object.assign({}, ...txReceipts))));
        }
        catch (err) {
            setError(err instanceof Error ? err : new Error("An error occurred."));
        }
    }), [currentPage]);
    (0, react_1.useEffect)(() => {
        fetchBlocks();
    }, [fetchBlocks]);
    (0, react_1.useEffect)(() => {
        const handleNewBlock = (newBlock) => __awaiter(void 0, void 0, void 0, function* () {
            try {
                if (currentPage === 0) {
                    if (newBlock.transactions.length > 0) {
                        const transactionsDetails = yield Promise.all(newBlock.transactions.map((txHash) => exports.testClient.getTransaction({ hash: txHash })));
                        newBlock.transactions = transactionsDetails;
                    }
                    newBlock.transactions.forEach((tx) => (0, scaffold_eth_1.decodeTransactionData)(tx));
                    const receipts = yield Promise.all(newBlock.transactions.map((tx) => __awaiter(void 0, void 0, void 0, function* () {
                        try {
                            const receipt = yield exports.testClient.getTransactionReceipt({ hash: tx.hash });
                            return { [tx.hash]: receipt };
                        }
                        catch (err) {
                            setError(err instanceof Error ? err : new Error("An error occurred fetching receipt."));
                            throw err;
                        }
                    })));
                    setBlocks(prevBlocks => [newBlock, ...prevBlocks.slice(0, BLOCKS_PER_PAGE - 1)]);
                    setTransactionReceipts(prevReceipts => (Object.assign(Object.assign({}, prevReceipts), Object.assign({}, ...receipts))));
                }
                if (newBlock.number) {
                    setTotalBlocks(newBlock.number);
                }
            }
            catch (err) {
                setError(err instanceof Error ? err : new Error("An error occurred."));
            }
        });
        return exports.testClient.watchBlocks({ onBlock: handleNewBlock, includeTransactions: true });
    }, [currentPage]);
    return {
        blocks,
        transactionReceipts,
        currentPage,
        totalBlocks,
        setCurrentPage,
        error,
    };
};
exports.useFetchBlocks = useFetchBlocks;
