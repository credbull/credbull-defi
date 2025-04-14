export type PeriodRate = {
  interestRate: bigint;
  effectiveFromPeriod: bigint;
};

export type DepositPool = {
  depositId: bigint;
  shares: bigint;
  assets: bigint;
  unlockRequestAmount: bigint;
  yield: bigint;
};

export type RedeemRequest = {
  id: number;
  shareAmount: bigint;
  assetAmount: bigint;
};
