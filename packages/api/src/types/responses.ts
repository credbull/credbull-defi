import { PostgrestError } from '@supabase/supabase-js';
import { ContractReceipt, ContractTransaction } from 'ethers';
import { SiweError } from 'siwe';

export type ServiceResponse<T> = { error?: null; data: T } | { error: Error | PostgrestError | SiweError; data?: null };

export const fromPromiseToResponse = <T>(p: Promise<T>): Promise<ServiceResponse<T>> =>
  p.then(async (data) => ({ data })).catch((error: Error) => ({ error }));

export const fromPromiseToReceipt = (p: Promise<ContractTransaction>): Promise<ServiceResponse<ContractReceipt>> =>
  p.then(async (tx: ContractTransaction) => ({ data: await tx.wait() })).catch((error: Error) => ({ error }));
