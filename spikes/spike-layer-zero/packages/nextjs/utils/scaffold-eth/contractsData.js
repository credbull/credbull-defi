"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useAllContracts = useAllContracts;
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
const contract_1 = require("~~/utils/scaffold-eth/contract");
const DEFAULT_ALL_CONTRACTS = {};
function useAllContracts() {
    const { targetNetwork } = (0, scaffold_eth_1.useTargetNetwork)();
    const contractsData = contract_1.contracts === null || contract_1.contracts === void 0 ? void 0 : contract_1.contracts[targetNetwork.id];
    // using constant to avoid creating a new object on every call
    return contractsData || DEFAULT_ALL_CONTRACTS;
}
