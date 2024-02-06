/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BytesLike,
  CallOverrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
} from "../common";

export interface WhitelistPlugInInterface extends utils.Interface {
  functions: {
    "checkWhitelist()": FunctionFragment;
    "kycProvider()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic: "checkWhitelist" | "kycProvider"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "checkWhitelist",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "kycProvider",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "checkWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "kycProvider",
    data: BytesLike
  ): Result;

  events: {};
}

export interface WhitelistPlugIn extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: WhitelistPlugInInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    checkWhitelist(overrides?: CallOverrides): Promise<[boolean]>;

    kycProvider(overrides?: CallOverrides): Promise<[string]>;
  };

  checkWhitelist(overrides?: CallOverrides): Promise<boolean>;

  kycProvider(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    checkWhitelist(overrides?: CallOverrides): Promise<boolean>;

    kycProvider(overrides?: CallOverrides): Promise<string>;
  };

  filters: {};

  estimateGas: {
    checkWhitelist(overrides?: CallOverrides): Promise<BigNumber>;

    kycProvider(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    checkWhitelist(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    kycProvider(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
