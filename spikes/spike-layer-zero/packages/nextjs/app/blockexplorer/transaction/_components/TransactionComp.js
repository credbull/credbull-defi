"use strict";
"use client";
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
const react_1 = require("react");
const navigation_1 = require("next/navigation");
const viem_1 = require("viem");
const chains_1 = require("viem/chains");
const wagmi_1 = require("wagmi");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const useTargetNetwork_1 = require("~~/hooks/scaffold-eth/useTargetNetwork");
const scaffold_eth_2 = require("~~/utils/scaffold-eth");
const common_1 = require("~~/utils/scaffold-eth/common");
const TransactionComp = ({ txHash }) => {
    var _a;
    const client = (0, wagmi_1.usePublicClient)({ chainId: chains_1.hardhat.id });
    const router = (0, navigation_1.useRouter)();
    const [transaction, setTransaction] = (0, react_1.useState)();
    const [receipt, setReceipt] = (0, react_1.useState)();
    const [functionCalled, setFunctionCalled] = (0, react_1.useState)();
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    (0, react_1.useEffect)(() => {
        if (txHash && client) {
            const fetchTransaction = () => __awaiter(void 0, void 0, void 0, function* () {
                const tx = yield client.getTransaction({ hash: txHash });
                const receipt = yield client.getTransactionReceipt({ hash: txHash });
                const transactionWithDecodedData = (0, scaffold_eth_2.decodeTransactionData)(tx);
                setTransaction(transactionWithDecodedData);
                setReceipt(receipt);
                const functionCalled = transactionWithDecodedData.input.substring(0, 10);
                setFunctionCalled(functionCalled);
            });
            fetchTransaction();
        }
    }, [client, txHash]);
    return (<div className="container mx-auto mt-10 mb-20 px-10 md:px-0">
      <button className="btn btn-sm btn-primary" onClick={() => router.back()}>
        Back
      </button>
      {transaction ? (<div className="overflow-x-auto">
          <h2 className="text-3xl font-bold mb-4 text-center text-primary-content">Transaction Details</h2>{" "}
          <table className="table rounded-lg bg-base-100 w-full shadow-lg md:table-lg table-md">
            <tbody>
              <tr>
                <td>
                  <strong>Transaction Hash:</strong>
                </td>
                <td>{transaction.hash}</td>
              </tr>
              <tr>
                <td>
                  <strong>Block Number:</strong>
                </td>
                <td>{Number(transaction.blockNumber)}</td>
              </tr>
              <tr>
                <td>
                  <strong>From:</strong>
                </td>
                <td>
                  <scaffold_eth_1.Address address={transaction.from} format="long"/>
                </td>
              </tr>
              <tr>
                <td>
                  <strong>To:</strong>
                </td>
                <td>
                  {!(receipt === null || receipt === void 0 ? void 0 : receipt.contractAddress) ? (transaction.to && <scaffold_eth_1.Address address={transaction.to} format="long"/>) : (<span>
                      Contract Creation:
                      <scaffold_eth_1.Address address={receipt.contractAddress} format="long"/>
                    </span>)}
                </td>
              </tr>
              <tr>
                <td>
                  <strong>Value:</strong>
                </td>
                <td>
                  {(0, viem_1.formatEther)(transaction.value)} {targetNetwork.nativeCurrency.symbol}
                </td>
              </tr>
              <tr>
                <td>
                  <strong>Function called:</strong>
                </td>
                <td>
                  <div className="w-full md:max-w-[600px] lg:max-w-[800px] overflow-x-auto whitespace-nowrap">
                    {functionCalled === "0x" ? ("This transaction did not call any function.") : (<>
                        <span className="mr-2">{(0, scaffold_eth_2.getFunctionDetails)(transaction)}</span>
                        <span className="badge badge-primary font-bold">{functionCalled}</span>
                      </>)}
                  </div>
                </td>
              </tr>
              <tr>
                <td>
                  <strong>Gas Price:</strong>
                </td>
                <td>{(0, viem_1.formatUnits)(transaction.gasPrice || 0n, 9)} Gwei</td>
              </tr>
              <tr>
                <td>
                  <strong>Data:</strong>
                </td>
                <td className="form-control">
                  <textarea readOnly value={transaction.input} className="p-0 textarea-primary bg-inherit h-[150px]"/>
                </td>
              </tr>
              <tr>
                <td>
                  <strong>Logs:</strong>
                </td>
                <td>
                  <ul>
                    {(_a = receipt === null || receipt === void 0 ? void 0 : receipt.logs) === null || _a === void 0 ? void 0 : _a.map((log, i) => (<li key={i}>
                        <strong>Log {i} topics:</strong> {JSON.stringify(log.topics, common_1.replacer, 2)}
                      </li>))}
                  </ul>
                </td>
              </tr>
            </tbody>
          </table>
        </div>) : (<p className="text-2xl text-base-content">Loading...</p>)}
    </div>);
};
exports.default = TransactionComp;
