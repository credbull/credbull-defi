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
exports.useContractLogs = void 0;
const react_1 = require("react");
const useTargetNetwork_1 = require("./useTargetNetwork");
const wagmi_1 = require("wagmi");
const useContractLogs = (address) => {
    const [logs, setLogs] = (0, react_1.useState)([]);
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const client = (0, wagmi_1.usePublicClient)({ chainId: targetNetwork.id });
    (0, react_1.useEffect)(() => {
        const fetchLogs = () => __awaiter(void 0, void 0, void 0, function* () {
            if (!client)
                return console.error("Client not found");
            try {
                const existingLogs = yield client.getLogs({
                    address: address,
                    fromBlock: 0n,
                    toBlock: "latest",
                });
                setLogs(existingLogs);
            }
            catch (error) {
                console.error("Failed to fetch logs:", error);
            }
        });
        fetchLogs();
        return client === null || client === void 0 ? void 0 : client.watchBlockNumber({
            onBlockNumber: (_blockNumber, prevBlockNumber) => __awaiter(void 0, void 0, void 0, function* () {
                const newLogs = yield client.getLogs({
                    address: address,
                    fromBlock: prevBlockNumber,
                    toBlock: "latest",
                });
                setLogs(prevLogs => [...prevLogs, ...newLogs]);
            }),
        });
    }, [address, client]);
    return logs;
};
exports.useContractLogs = useContractLogs;
