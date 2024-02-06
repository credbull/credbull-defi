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
} from "./common";

export interface CredbullEntitiesInterface extends utils.Interface {
  functions: {
    "activityReward()": FunctionFragment;
    "custodian()": FunctionFragment;
    "kycProvider()": FunctionFragment;
    "treasury()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "activityReward"
      | "custodian"
      | "kycProvider"
      | "treasury"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "activityReward",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "custodian", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "kycProvider",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "treasury", values?: undefined): string;

  decodeFunctionResult(
    functionFragment: "activityReward",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "custodian", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "kycProvider",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "treasury", data: BytesLike): Result;

  events: {};
}

export interface CredbullEntities extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: CredbullEntitiesInterface;

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
    activityReward(overrides?: CallOverrides): Promise<[string]>;

    custodian(overrides?: CallOverrides): Promise<[string]>;

    kycProvider(overrides?: CallOverrides): Promise<[string]>;

    treasury(overrides?: CallOverrides): Promise<[string]>;
  };

  activityReward(overrides?: CallOverrides): Promise<string>;

  custodian(overrides?: CallOverrides): Promise<string>;

  kycProvider(overrides?: CallOverrides): Promise<string>;

  treasury(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    activityReward(overrides?: CallOverrides): Promise<string>;

    custodian(overrides?: CallOverrides): Promise<string>;

    kycProvider(overrides?: CallOverrides): Promise<string>;

    treasury(overrides?: CallOverrides): Promise<string>;
  };

  filters: {};

  estimateGas: {
    activityReward(overrides?: CallOverrides): Promise<BigNumber>;

    custodian(overrides?: CallOverrides): Promise<BigNumber>;

    kycProvider(overrides?: CallOverrides): Promise<BigNumber>;

    treasury(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    activityReward(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    custodian(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    kycProvider(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    treasury(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}