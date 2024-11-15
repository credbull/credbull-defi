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
exports.ContractTabs = void 0;
const react_1 = require("react");
const AddressCodeTab_1 = require("./AddressCodeTab");
const AddressLogsTab_1 = require("./AddressLogsTab");
const AddressStorageTab_1 = require("./AddressStorageTab");
const PaginationButton_1 = require("./PaginationButton");
const TransactionsTable_1 = require("./TransactionsTable");
const viem_1 = require("viem");
const chains_1 = require("viem/chains");
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
const publicClient = (0, viem_1.createPublicClient)({
    chain: chains_1.hardhat,
    transport: (0, viem_1.http)(),
});
const ContractTabs = ({ address, contractData }) => {
    const { blocks, transactionReceipts, currentPage, totalBlocks, setCurrentPage } = (0, scaffold_eth_1.useFetchBlocks)();
    const [activeTab, setActiveTab] = (0, react_1.useState)("transactions");
    const [isContract, setIsContract] = (0, react_1.useState)(false);
    (0, react_1.useEffect)(() => {
        const checkIsContract = () => __awaiter(void 0, void 0, void 0, function* () {
            const contractCode = yield publicClient.getBytecode({ address: address });
            setIsContract(contractCode !== undefined && contractCode !== "0x");
        });
        checkIsContract();
    }, [address]);
    const filteredBlocks = blocks.filter(block => block.transactions.some(tx => {
        var _a;
        if (typeof tx === "string") {
            return false;
        }
        return tx.from.toLowerCase() === address.toLowerCase() || ((_a = tx.to) === null || _a === void 0 ? void 0 : _a.toLowerCase()) === address.toLowerCase();
    }));
    return (<>
      {isContract && (<div className="tabs tabs-lifted w-min">
          <button className={`tab ${activeTab === "transactions" ? "tab-active" : ""}`} onClick={() => setActiveTab("transactions")}>
            Transactions
          </button>
          <button className={`tab ${activeTab === "code" ? "tab-active" : ""}`} onClick={() => setActiveTab("code")}>
            Code
          </button>
          <button className={`tab  ${activeTab === "storage" ? "tab-active" : ""}`} onClick={() => setActiveTab("storage")}>
            Storage
          </button>
          <button className={`tab  ${activeTab === "logs" ? "tab-active" : ""}`} onClick={() => setActiveTab("logs")}>
            Logs
          </button>
        </div>)}
      {activeTab === "transactions" && (<div className="pt-4">
          <TransactionsTable_1.TransactionsTable blocks={filteredBlocks} transactionReceipts={transactionReceipts}/>
          <PaginationButton_1.PaginationButton currentPage={currentPage} totalItems={Number(totalBlocks)} setCurrentPage={setCurrentPage}/>
        </div>)}
      {activeTab === "code" && contractData && (<AddressCodeTab_1.AddressCodeTab bytecode={contractData.bytecode} assembly={contractData.assembly}/>)}
      {activeTab === "storage" && <AddressStorageTab_1.AddressStorageTab address={address}/>}
      {activeTab === "logs" && <AddressLogsTab_1.AddressLogsTab address={address}/>}
    </>);
};
exports.ContractTabs = ContractTabs;
