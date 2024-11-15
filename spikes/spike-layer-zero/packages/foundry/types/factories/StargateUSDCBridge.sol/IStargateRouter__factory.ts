/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IStargateRouter,
  IStargateRouterInterface,
} from "../../StargateUSDCBridge.sol/IStargateRouter";

const _abi = [
  {
    type: "function",
    name: "addLiquidity",
    inputs: [
      {
        name: "_poolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_amountLD",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_to",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "instantRedeemLocal",
    inputs: [
      {
        name: "_srcPoolId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_amountLP",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_to",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "quoteLayerZeroFee",
    inputs: [
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_functionType",
        type: "uint8",
        internalType: "uint8",
      },
      {
        name: "_toAddress",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "_transferAndCallPayload",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "_lzTxParams",
        type: "tuple",
        internalType: "struct IStargateRouter.lzTxObj",
        components: [
          {
            name: "dstGasForCall",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "dstNativeAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "dstNativeAddr",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
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
    name: "redeemLocal",
    inputs: [
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_srcPoolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_dstPoolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_refundAddress",
        type: "address",
        internalType: "address payable",
      },
      {
        name: "_amountLP",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_to",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "_lzTxParams",
        type: "tuple",
        internalType: "struct IStargateRouter.lzTxObj",
        components: [
          {
            name: "dstGasForCall",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "dstNativeAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "dstNativeAddr",
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
    name: "redeemRemote",
    inputs: [
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_srcPoolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_dstPoolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_refundAddress",
        type: "address",
        internalType: "address payable",
      },
      {
        name: "_amountLP",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_minAmountLD",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_to",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "_lzTxParams",
        type: "tuple",
        internalType: "struct IStargateRouter.lzTxObj",
        components: [
          {
            name: "dstGasForCall",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "dstNativeAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "dstNativeAddr",
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
    name: "sendCredits",
    inputs: [
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_srcPoolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_dstPoolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_refundAddress",
        type: "address",
        internalType: "address payable",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "swap",
    inputs: [
      {
        name: "_dstChainId",
        type: "uint16",
        internalType: "uint16",
      },
      {
        name: "_srcPoolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_dstPoolId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_refundAddress",
        type: "address",
        internalType: "address payable",
      },
      {
        name: "_amountLD",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_minAmountLD",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_lzTxParams",
        type: "tuple",
        internalType: "struct IStargateRouter.lzTxObj",
        components: [
          {
            name: "dstGasForCall",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "dstNativeAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "dstNativeAddr",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
      {
        name: "_to",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "_payload",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
] as const;

export class IStargateRouter__factory {
  static readonly abi = _abi;
  static createInterface(): IStargateRouterInterface {
    return new utils.Interface(_abi) as IStargateRouterInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IStargateRouter {
    return new Contract(address, _abi, signerOrProvider) as IStargateRouter;
  }
}
