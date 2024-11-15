"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getFunctionDetails = exports.decodeTransactionData = void 0;
const viem_1 = require("viem");
const chains_1 = require("viem/chains");
const deployedContracts_1 = __importDefault(require("~~/contracts/deployedContracts"));
const deployedContracts = deployedContracts_1.default;
const chainMetaData = deployedContracts === null || deployedContracts === void 0 ? void 0 : deployedContracts[chains_1.hardhat.id];
const interfaces = chainMetaData
    ? Object.entries(chainMetaData).reduce((finalInterfacesObj, [contractName, contract]) => {
        finalInterfacesObj[contractName] = contract.abi;
        return finalInterfacesObj;
    }, {})
    : {};
const decodeTransactionData = (tx) => {
    var _a, _b, _c;
    if (tx.input.length >= 10 && !tx.input.startsWith("0x60e06040")) {
        for (const [, contractAbi] of Object.entries(interfaces)) {
            try {
                const { functionName, args } = (0, viem_1.decodeFunctionData)({
                    abi: contractAbi,
                    data: tx.input,
                });
                tx.functionName = functionName;
                tx.functionArgs = args;
                tx.functionArgNames = (_b = (_a = (0, viem_1.getAbiItem)({
                    abi: contractAbi,
                    name: functionName,
                })) === null || _a === void 0 ? void 0 : _a.inputs) === null || _b === void 0 ? void 0 : _b.map((input) => input.name);
                tx.functionArgTypes = (_c = (0, viem_1.getAbiItem)({
                    abi: contractAbi,
                    name: functionName,
                })) === null || _c === void 0 ? void 0 : _c.inputs.map((input) => input.type);
                break;
            }
            catch (e) {
                console.error(`Parsing failed: ${e}`);
            }
        }
    }
    return tx;
};
exports.decodeTransactionData = decodeTransactionData;
const getFunctionDetails = (transaction) => {
    if (transaction &&
        transaction.functionName &&
        transaction.functionArgNames &&
        transaction.functionArgTypes &&
        transaction.functionArgs) {
        const details = transaction.functionArgNames.map((name, i) => { var _a, _b, _c; return `${((_a = transaction.functionArgTypes) === null || _a === void 0 ? void 0 : _a[i]) || ""} ${name} = ${(_c = (_b = transaction.functionArgs) === null || _b === void 0 ? void 0 : _b[i]) !== null && _c !== void 0 ? _c : ""}`; });
        return `${transaction.functionName}(${details.join(", ")})`;
    }
    return "";
};
exports.getFunctionDetails = getFunctionDetails;
