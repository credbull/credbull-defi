import { ethers } from 'ethers';

export function decodeContractError(contract: ethers.Contract, errorData: string) {
  const contractInterface = contract.interface;
  const selecter = errorData.slice(0, 10);
  const errorFragment = contractInterface.getError(selecter);
  const res = contractInterface.decodeErrorResult(errorFragment, errorData);
  const errorInputs = errorFragment.inputs;

  let message;
  if (errorInputs.length > 0) {
    message = errorInputs
      .map((input, index) => {
        return `${input.name}: ${res[index].toString()}`;
      })
      .join(', ');
  }

  return new Error(`${errorFragment.name} | ${message ? message : ''}`);
}

export function handleError(contract: ethers.Contract, error: any) {
  const errorToDecode = error.error?.data?.data ?? error.error?.error?.error?.data ?? error.error?.error?.data ?? '';

  if (errorToDecode != '') {
    return decodeContractError(contract, errorToDecode);
  }

  return new Error(error);
}
