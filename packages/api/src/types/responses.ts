import { Contract } from 'ethers';

import { handleError } from '../utils/decoder';
import { KnownError, UnknownError } from '../utils/errors';

export type ServiceResponse<T> =
  | { error?: null; data: T }
  | {
      error: KnownError | UnknownError;
      data?: null;
    };

export const promiseToResponse = <T, D>(
  c: Contract,
  p: Promise<D>,
  normalise: (data: D) => Promise<T>,
): Promise<ServiceResponse<T>> =>
  p
    .then(async (data) => ({ data: await normalise(data) }))
    .catch((error: Error) => ({
      error: handleError(c, error),
    }));
