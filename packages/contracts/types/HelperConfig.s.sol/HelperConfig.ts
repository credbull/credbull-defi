/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
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

export type FactoryParamsStruct = { owner: string; operator: string };

export type FactoryParamsStructOutput = [string, string] & {
  owner: string;
  operator: string;
};

export type NetworkConfigStruct = {
  vaultParams: ICredbull.VaultParamsStruct;
  entities: ICredbull.EntitiesStruct;
  factoryParams: FactoryParamsStruct;
};

export type NetworkConfigStructOutput = [
  ICredbull.VaultParamsStructOutput,
  ICredbull.EntitiesStructOutput,
  FactoryParamsStructOutput
] & {
  vaultParams: ICredbull.VaultParamsStructOutput;
  entities: ICredbull.EntitiesStructOutput;
  factoryParams: FactoryParamsStructOutput;
};

export declare namespace ICredbull {
  export type VaultParamsStruct = {
    owner: string;
    operator: string;
    asset: string;
    shareName: string;
    shareSymbol: string;
    promisedYield: BigNumberish;
    depositOpensAt: BigNumberish;
    depositClosesAt: BigNumberish;
    redemptionOpensAt: BigNumberish;
    redemptionClosesAt: BigNumberish;
    custodian: string;
    kycProvider: string;
    treasury: string;
    activityReward: string;
  };

  export type VaultParamsStructOutput = [
    string,
    string,
    string,
    string,
    string,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    string,
    string,
    string,
    string
  ] & {
    owner: string;
    operator: string;
    asset: string;
    shareName: string;
    shareSymbol: string;
    promisedYield: BigNumber;
    depositOpensAt: BigNumber;
    depositClosesAt: BigNumber;
    redemptionOpensAt: BigNumber;
    redemptionClosesAt: BigNumber;
    custodian: string;
    kycProvider: string;
    treasury: string;
    activityReward: string;
  };

  export type EntitiesStruct = {
    kycProvider: string;
    treasury: string;
    activityReward: string;
    custodian: string;
  };

  export type EntitiesStructOutput = [string, string, string, string] & {
    kycProvider: string;
    treasury: string;
    activityReward: string;
    custodian: string;
  };
}

export interface HelperConfigInterface extends utils.Interface {
  functions: {
    "IS_SCRIPT()": FunctionFragment;
    "getNetworkConfig()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic: "IS_SCRIPT" | "getNetworkConfig"
  ): FunctionFragment;

  encodeFunctionData(functionFragment: "IS_SCRIPT", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "getNetworkConfig",
    values?: undefined
  ): string;

  decodeFunctionResult(functionFragment: "IS_SCRIPT", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getNetworkConfig",
    data: BytesLike
  ): Result;

  events: {};
}

export interface HelperConfig extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: HelperConfigInterface;

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
    IS_SCRIPT(overrides?: CallOverrides): Promise<[boolean]>;

    getNetworkConfig(
      overrides?: CallOverrides
    ): Promise<[NetworkConfigStructOutput]>;
  };

  IS_SCRIPT(overrides?: CallOverrides): Promise<boolean>;

  getNetworkConfig(
    overrides?: CallOverrides
  ): Promise<NetworkConfigStructOutput>;

  callStatic: {
    IS_SCRIPT(overrides?: CallOverrides): Promise<boolean>;

    getNetworkConfig(
      overrides?: CallOverrides
    ): Promise<NetworkConfigStructOutput>;
  };

  filters: {};

  estimateGas: {
    IS_SCRIPT(overrides?: CallOverrides): Promise<BigNumber>;

    getNetworkConfig(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    IS_SCRIPT(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getNetworkConfig(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}