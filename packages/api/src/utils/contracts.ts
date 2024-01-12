import { ContractReceipt, ContractTransaction } from 'ethers';

import { ServiceResponse, promiseToResponse } from '../types/responses';

export const responseFromRead = <T>(p: Promise<T>): Promise<ServiceResponse<T>> =>
  promiseToResponse(p, (data) => Promise.resolve(data));

export const responseFromWrite = (p: Promise<ContractTransaction>): Promise<ServiceResponse<ContractReceipt>> =>
  promiseToResponse(p, (data) => data.wait());
