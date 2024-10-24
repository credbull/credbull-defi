"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.StdStorageSafe__factory = void 0;
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
const ethers_1 = require("ethers");
const _abi = [
    {
        type: "event",
        name: "SlotFound",
        inputs: [
            {
                name: "who",
                type: "address",
                indexed: false,
                internalType: "address",
            },
            {
                name: "fsig",
                type: "bytes4",
                indexed: false,
                internalType: "bytes4",
            },
            {
                name: "keysHash",
                type: "bytes32",
                indexed: false,
                internalType: "bytes32",
            },
            {
                name: "slot",
                type: "uint256",
                indexed: false,
                internalType: "uint256",
            },
        ],
        anonymous: false,
    },
    {
        type: "event",
        name: "WARNING_UninitedSlot",
        inputs: [
            {
                name: "who",
                type: "address",
                indexed: false,
                internalType: "address",
            },
            {
                name: "slot",
                type: "uint256",
                indexed: false,
                internalType: "uint256",
            },
        ],
        anonymous: false,
    },
];
const _bytecode = "0x60566037600b82828239805160001a607314602a57634e487b7160e01b600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea2646970667358221220ce3315aa7ee580eb1bcfd39988b0d8bd8f7fe4d29a0dba9224e7dc5997d7c78664736f6c63430008180033";
const isSuperArgs = (xs) => xs.length > 1;
class StdStorageSafe__factory extends ethers_1.ContractFactory {
    constructor(...args) {
        if (isSuperArgs(args)) {
            super(...args);
        }
        else {
            super(_abi, _bytecode, args[0]);
        }
    }
    deploy(overrides) {
        return super.deploy(overrides || {});
    }
    getDeployTransaction(overrides) {
        return super.getDeployTransaction(overrides || {});
    }
    attach(address) {
        return super.attach(address);
    }
    connect(signer) {
        return super.connect(signer);
    }
    static createInterface() {
        return new ethers_1.utils.Interface(_abi);
    }
    static connect(address, signerOrProvider) {
        return new ethers_1.Contract(address, _abi, signerOrProvider);
    }
}
exports.StdStorageSafe__factory = StdStorageSafe__factory;
StdStorageSafe__factory.bytecode = _bytecode;
StdStorageSafe__factory.abi = _abi;
