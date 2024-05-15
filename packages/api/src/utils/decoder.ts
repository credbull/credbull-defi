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
  if (error.error?.data?.data) {
    return decodeContractError(contract, error.error.data.data);
  } else if (error.error?.error?.error?.data) {
    return decodeContractError(contract, error.error.error.error.data);
  } else if (error.error?.error?.data) {
    return decodeContractError(contract, error.error.error.data);
  } else {
    return new Error(error);
  }
}
