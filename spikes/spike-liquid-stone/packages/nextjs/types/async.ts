export type LockRow = {
    depositPeriod: number;
    lockedAmount: bigint;
    maxRequestUnlock: bigint;
    unlockRequestAmount: bigint;   
};