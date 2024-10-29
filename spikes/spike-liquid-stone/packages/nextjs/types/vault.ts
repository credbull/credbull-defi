import { OwnedNft } from "alchemy-sdk";

export type PeriodRate = {
  interestRate: bigint;
  effectiveFromPeriod: bigint;
};

export type DepositPool = {
  depositId: OwnedNft;
  balance: string;
  shares: string;
  unlockRequestAmount: string;
  yield: string;
};

export type RedeemRequest = {
  id: number;
  shareAmount: bigint;
  assetAmount: bigint;
};
