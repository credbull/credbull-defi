/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
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

export interface AKYCProviderInterface extends utils.Interface {
  functions: {
    "status(address)": FunctionFragment;
    "updateStatus(address[],bool[])": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic: "status" | "updateStatus"
  ): FunctionFragment;

  encodeFunctionData(functionFragment: "status", values: [string]): string;
  encodeFunctionData(
    functionFragment: "updateStatus",
    values: [string[], boolean[]]
  ): string;

  decodeFunctionResult(functionFragment: "status", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "updateStatus",
    data: BytesLike
  ): Result;

  events: {};
}

export interface AKYCProvider extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: AKYCProviderInterface;

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
    status(receiver: string, overrides?: CallOverrides): Promise<[boolean]>;

    updateStatus(
      _addresses: string[],
      _statuses: boolean[],
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;
  };

  status(receiver: string, overrides?: CallOverrides): Promise<boolean>;

  updateStatus(
    _addresses: string[],
    _statuses: boolean[],
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  callStatic: {
    status(receiver: string, overrides?: CallOverrides): Promise<boolean>;

    updateStatus(
      _addresses: string[],
      _statuses: boolean[],
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    status(receiver: string, overrides?: CallOverrides): Promise<BigNumber>;

    updateStatus(
      _addresses: string[],
      _statuses: boolean[],
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    status(
      receiver: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    updateStatus(
      _addresses: string[],
      _statuses: boolean[],
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;
  };
}
