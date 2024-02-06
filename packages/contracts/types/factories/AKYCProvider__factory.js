"use strict";
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
Object.defineProperty(exports, "__esModule", { value: true });
exports.AKYCProvider__factory = void 0;
const ethers_1 = require("ethers");
const _abi = [
    {
        inputs: [
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
        ],
        name: "status",
        outputs: [
            {
                internalType: "bool",
                name: "",
                type: "bool",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address[]",
                name: "_addresses",
                type: "address[]",
            },
            {
                internalType: "bool[]",
                name: "_statuses",
                type: "bool[]",
            },
        ],
        name: "updateStatus",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
];
class AKYCProvider__factory {
    static createInterface() {
        return new ethers_1.utils.Interface(_abi);
    }
    static connect(address, signerOrProvider) {
        return new ethers_1.Contract(address, _abi, signerOrProvider);
    }
}
exports.AKYCProvider__factory = AKYCProvider__factory;
AKYCProvider__factory.abi = _abi;
