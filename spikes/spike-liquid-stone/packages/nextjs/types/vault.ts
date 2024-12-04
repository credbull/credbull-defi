export type PeriodRate = {
  interestRate: bigint;
  effectiveFromPeriod: bigint;
};

export type DepositPool = {
  depositId: string;
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
