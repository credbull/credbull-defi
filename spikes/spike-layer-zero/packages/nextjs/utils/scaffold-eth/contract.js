"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ContractCodeStatus = exports.contracts = void 0;
const deployedContracts_1 = __importDefault(require("~~/contracts/deployedContracts"));
const externalContracts_1 = __importDefault(require("~~/contracts/externalContracts"));
const deepMergeContracts = (local, external) => {
    const result = {};
    const allKeys = Array.from(new Set([...Object.keys(external), ...Object.keys(local)]));
    for (const key of allKeys) {
        if (!external[key]) {
            result[key] = local[key];
            continue;
        }
        const amendedExternal = Object.fromEntries(Object.entries(external[key]).map(([contractName, declaration]) => [
            contractName,
            Object.assign(Object.assign({}, declaration), { external: true }),
        ]));
        result[key] = Object.assign(Object.assign({}, local[key]), amendedExternal);
    }
    return result;
};
const contractsData = deepMergeContracts(deployedContracts_1.default, externalContracts_1.default);
exports.contracts = contractsData;
var ContractCodeStatus;
(function (ContractCodeStatus) {
    ContractCodeStatus[ContractCodeStatus["LOADING"] = 0] = "LOADING";
    ContractCodeStatus[ContractCodeStatus["DEPLOYED"] = 1] = "DEPLOYED";
    ContractCodeStatus[ContractCodeStatus["NOT_FOUND"] = 2] = "NOT_FOUND";
})(ContractCodeStatus || (exports.ContractCodeStatus = ContractCodeStatus = {}));
