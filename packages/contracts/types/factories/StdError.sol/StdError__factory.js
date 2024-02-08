"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.StdError__factory = void 0;
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
const ethers_1 = require("ethers");
const _abi = [
    {
        type: "function",
        name: "arithmeticError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "assertionError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "divisionError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "encodeStorageError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "enumConversionError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "indexOOBError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "memOverflowError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "popError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "zeroVarError",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes",
                internalType: "bytes",
            },
        ],
        stateMutability: "view",
    },
];
const _bytecode = "0x61025061003a600b82828239805160001a60731461002d57634e487b7160e01b600052600060045260246000fd5b30600052607381538281f3fe730000000000000000000000000000000000000000301460806040526004361061009d5760003560e01c8063986c5f6811610070578063986c5f68146100d8578063b22dc54d146100e0578063b67689da146100e8578063d160e4de146100f0578063fa784a44146100f857600080fd5b806305ee8612146100a257806310332977146100c05780631de45560146100c85780638995290f146100d0575b600080fd5b6100aa610100565b6040516100b791906101cb565b60405180910390f35b6100aa61013b565b6100aa61014d565b6100aa61015f565b6100aa610171565b6100aa610183565b6100aa610195565b6100aa6101a7565b6100aa6101b9565b604051603260248201526044015b60408051601f198184030181529190526020810180516001600160e01b0316634e487b7160e01b17905281565b6040516001602482015260440161010e565b6040516021602482015260440161010e565b6040516011602482015260440161010e565b6040516041602482015260440161010e565b6040516031602482015260440161010e565b6040516051602482015260440161010e565b6040516022602482015260440161010e565b6040516012602482015260440161010e565b60006020808352835180602085015260005b818110156101f9578581018301518582016040015282016101dd565b506000604082860101526040601f19601f830116850101925050509291505056fea26469706673582212205b4ec80a0806a34bac61b9c2ebdbe737cd537b28c85998437e0d5ea524d8809a64736f6c63430008170033";
const isSuperArgs = (xs) => xs.length > 1;
class StdError__factory extends ethers_1.ContractFactory {
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
exports.StdError__factory = StdError__factory;
StdError__factory.bytecode = _bytecode;
StdError__factory.abi = _abi;
