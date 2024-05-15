import { Contract, ContractReceipt, ContractTransaction } from 'ethers';

import { ServiceResponse, promiseToResponse } from '../types/responses';

export const responseFromRead = <T>(c: Contract, p: Promise<T>): Promise<ServiceResponse<T>> =>
  promiseToResponse(c, p, (data) => Promise.resolve(data));

export const responseFromWrite = (
  c: Contract,
  p: Promise<ContractTransaction>,
): Promise<ServiceResponse<ContractReceipt>> => promiseToResponse(c, p, (data) => data.wait());
