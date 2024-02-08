"use strict";
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
Object.defineProperty(exports, "__esModule", { value: true });
exports.WindowPlugIn__factory = void 0;
const ethers_1 = require("ethers");
const _abi = [
    {
        type: "function",
        name: "checkWindow",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bool",
                internalType: "bool",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "depositClosesAtTimestamp",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "uint256",
                internalType: "uint256",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "depositOpensAtTimestamp",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "uint256",
                internalType: "uint256",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "redemptionClosesAtTimestamp",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "uint256",
                internalType: "uint256",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "redemptionOpensAtTimestamp",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "uint256",
                internalType: "uint256",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "error",
        name: "CredbullVault__OperationOutsideRequiredWindow",
        inputs: [
            {
                name: "windowOpensAt",
                type: "uint256",
                internalType: "uint256",
            },
            {
                name: "windowClosesAt",
                type: "uint256",
                internalType: "uint256",
            },
            {
                name: "timestamp",
                type: "uint256",
                internalType: "uint256",
            },
        ],
    },
];
class WindowPlugIn__factory {
    static createInterface() {
        return new ethers_1.utils.Interface(_abi);
    }
    static connect(address, signerOrProvider) {
        return new ethers_1.Contract(address, _abi, signerOrProvider);
    }
}
exports.WindowPlugIn__factory = WindowPlugIn__factory;
WindowPlugIn__factory.abi = _abi;