"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TransactionsTable = void 0;
const TransactionHash_1 = require("./TransactionHash");
const viem_1 = require("viem");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const useTargetNetwork_1 = require("~~/hooks/scaffold-eth/useTargetNetwork");
const TransactionsTable = ({ blocks, transactionReceipts }) => {
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    return (<div className="flex justify-center px-4 md:px-0">
      <div className="overflow-x-auto w-full shadow-2xl rounded-xl">
        <table className="table text-xl bg-base-100 table-zebra w-full md:table-md table-sm">
          <thead>
            <tr className="rounded-xl text-sm text-base-content">
              <th className="bg-primary">Transaction Hash</th>
              <th className="bg-primary">Function Called</th>
              <th className="bg-primary">Block Number</th>
              <th className="bg-primary">Time Mined</th>
              <th className="bg-primary">From</th>
              <th className="bg-primary">To</th>
              <th className="bg-primary text-end">Value ({targetNetwork.nativeCurrency.symbol})</th>
            </tr>
          </thead>
          <tbody>
            {blocks.map(block => block.transactions.map(tx => {
            var _a;
            const receipt = transactionReceipts[tx.hash];
            const timeMined = new Date(Number(block.timestamp) * 1000).toLocaleString();
            const functionCalled = tx.input.substring(0, 10);
            return (<tr key={tx.hash} className="hover text-sm">
                    <td className="w-1/12 md:py-4">
                      <TransactionHash_1.TransactionHash hash={tx.hash}/>
                    </td>
                    <td className="w-2/12 md:py-4">
                      {tx.functionName === "0x" ? "" : <span className="mr-1">{tx.functionName}</span>}
                      {functionCalled !== "0x" && (<span className="badge badge-primary font-bold text-xs">{functionCalled}</span>)}
                    </td>
                    <td className="w-1/12 md:py-4">{(_a = block.number) === null || _a === void 0 ? void 0 : _a.toString()}</td>
                    <td className="w-2/1 md:py-4">{timeMined}</td>
                    <td className="w-2/12 md:py-4">
                      <scaffold_eth_1.Address address={tx.from} size="sm"/>
                    </td>
                    <td className="w-2/12 md:py-4">
                      {!(receipt === null || receipt === void 0 ? void 0 : receipt.contractAddress) ? (tx.to && <scaffold_eth_1.Address address={tx.to} size="sm"/>) : (<div className="relative">
                          <scaffold_eth_1.Address address={receipt.contractAddress} size="sm"/>
                          <small className="absolute top-4 left-4">(Contract Creation)</small>
                        </div>)}
                    </td>
                    <td className="text-right md:py-4">
                      {(0, viem_1.formatEther)(tx.value)} {targetNetwork.nativeCurrency.symbol}
                    </td>
                  </tr>);
        }))}
          </tbody>
        </table>
      </div>
    </div>);
};
exports.TransactionsTable = TransactionsTable;
