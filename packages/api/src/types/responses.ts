import { PostgrestError } from '@supabase/supabase-js';
import { SiweError } from 'siwe';

export type ServiceResponse<T> =
  | { error?: null; data: T }
  | {
      error: Error | PostgrestError | SiweError;
      data?: null;
    };

export const promiseToResponse = <T, D>(
  p: Promise<D>,
  normalise: (data: D) => Promise<T>,
): Promise<ServiceResponse<T>> =>
  p.then(async (data) => ({ data: await normalise(data) })).catch((error: Error) => ({ error }));
