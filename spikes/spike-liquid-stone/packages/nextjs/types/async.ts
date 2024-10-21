export type LockRow = {
  depositPeriod: number;
  lockedAmount: bigint;
  maxRequestUnlock: bigint;
  unlockRequestAmount: bigint;
};

export type UnlockRequest = {
  requestId: number;
  unlockAmount: bigint;
};

export type RequestDetail = {
  depositPeriod: number;
  unlockAmount: bigint;
};
