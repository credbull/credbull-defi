"use strict";
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
Object.defineProperty(exports, "__esModule", { value: true });
exports.WhitelistPlugIn__factory = void 0;
const ethers_1 = require("ethers");
const _abi = [
    {
        type: "function",
        name: "checkWhitelist",
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
        name: "kycProvider",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "address",
                internalType: "contract AKYCProvider",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "error",
        name: "CredbullVault__NotAWhitelistedAddress",
        inputs: [],
    },
];
class WhitelistPlugIn__factory {
    static createInterface() {
        return new ethers_1.utils.Interface(_abi);
    }
    static connect(address, signerOrProvider) {
        return new ethers_1.Contract(address, _abi, signerOrProvider);
    }
}
exports.WhitelistPlugIn__factory = WhitelistPlugIn__factory;
WhitelistPlugIn__factory.abi = _abi;