/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  WhitelistPlugIn,
  WhitelistPlugInInterface,
} from "../WhitelistPlugIn";

const _abi = [
  {
    inputs: [],
    name: "CredbullVault__NotAWhitelistedAddress",
    type: "error",
  },
  {
    inputs: [],
    name: "checkWhitelist",
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
    inputs: [],
    name: "kycProvider",
    outputs: [
      {
        internalType: "contract AKYCProvider",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class WhitelistPlugIn__factory {
  static readonly abi = _abi;
  static createInterface(): WhitelistPlugInInterface {
    return new utils.Interface(_abi) as WhitelistPlugInInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): WhitelistPlugIn {
    return new Contract(address, _abi, signerOrProvider) as WhitelistPlugIn;
  }
}
