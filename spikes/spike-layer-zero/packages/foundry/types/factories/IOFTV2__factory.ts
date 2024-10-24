/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { IOFTV2, IOFTV2Interface } from "../IOFTV2";

const _abi = [
  {
    type: "function",
    name: "circulatingSupply",
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
    name: "estimateSendAndCallFee",
    inputs: [
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_toAddress",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "_amount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_payload",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "_dstGasForCall",
        type: "uint64",
        internalType: "uint64",
      },
      {
        name: "_useZro",
        type: "bool",
        internalType: "bool",
      },
      {
        name: "_adapterParams",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    outputs: [
      {
        name: "nativeFee",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "zroFee",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "estimateSendFee",
    inputs: [
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_toAddress",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "_amount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_useZro",
        type: "bool",
        internalType: "bool",
      },
      {
        name: "_adapterParams",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    outputs: [
      {
        name: "nativeFee",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "zroFee",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "sendAndCall",
    inputs: [
      {
        name: "_from",
        type: "address",
        internalType: "address",
      },
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_toAddress",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "_amount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_payload",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "_dstGasForCall",
        type: "uint64",
        internalType: "uint64",
      },
      {
        name: "_callParams",
        type: "tuple",
        internalType: "struct ICommonOFT.LzCallParams",
        components: [
          {
            name: "refundAddress",
            type: "address",
            internalType: "address payable",
          },
          {
            name: "zroPaymentAddress",
            type: "address",
            internalType: "address",
          },
          {
            name: "adapterParams",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "sendFrom",
    inputs: [
      {
        name: "_from",
        type: "address",
        internalType: "address",
      },
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_toAddress",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "_amount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_callParams",
        type: "tuple",
        internalType: "struct ICommonOFT.LzCallParams",
        components: [
          {
            name: "refundAddress",
            type: "address",
            internalType: "address payable",
          },
          {
            name: "zroPaymentAddress",
            type: "address",
            internalType: "address",
          },
          {
            name: "adapterParams",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "supportsInterface",
    inputs: [
      {
        name: "interfaceId",
        type: "bytes4",
        internalType: "bytes4",
      },
    ],
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
    name: "token",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "view",
  },
] as const;

export class IOFTV2__factory {
  static readonly abi = _abi;
  static createInterface(): IOFTV2Interface {
    return new utils.Interface(_abi) as IOFTV2Interface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): IOFTV2 {
    return new Contract(address, _abi, signerOrProvider) as IOFTV2;
  }
}
