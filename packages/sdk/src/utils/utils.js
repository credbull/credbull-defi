"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.decodeContractError = void 0;
function decodeContractError(contract, errorData) {
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
    throw new Error(`${errorFragment.name} | ${message ? message : ''}`);
}
exports.decodeContractError = decodeContractError;
