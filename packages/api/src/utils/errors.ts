import { PostgrestError } from '@supabase/supabase-js';
import { SiweError } from 'siwe';

export const NoDataFound = { message: 'No data found', known: true } as const;
export const NoDiscriminator = { message: 'No discriminator provided', known: true } as const;
export const DiscriminatorProvided = { message: 'Discriminator should not be provided', known: true } as const;
export const CustodianAmountLesserThanExpected = {
  message: 'Custodian amount should be bigger or same as expected amount',
  known: true,
} as const;

export type KnownError =
  | typeof NoDataFound
  | typeof NoDiscriminator
  | typeof DiscriminatorProvided
  | typeof CustodianAmountLesserThanExpected;

export type UnknownError = AggregateError | Error | PostgrestError | SiweError;

export const anyCallHasFailed = (calls: object[]) => {
  return calls.filter((o) => 'error' in o && Boolean(o.error)).length > 0;
};

export const isKnownError = (error: KnownError | UnknownError | null | undefined): error is KnownError => {
  return !!error && 'known' in error;
};
