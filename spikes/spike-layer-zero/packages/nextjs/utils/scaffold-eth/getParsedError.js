"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getParsedError = void 0;
const viem_1 = require("viem");
/**
 * Parses an viem/wagmi error to get a displayable string
 * @param e - error object
 * @returns parsed error string
 */
const getParsedError = (error) => {
    var _a, _b, _c, _d, _e;
    const parsedError = (error === null || error === void 0 ? void 0 : error.walk) ? error.walk() : error;
    if (parsedError instanceof viem_1.BaseError) {
        if (parsedError.details) {
            return parsedError.details;
        }
        if (parsedError.shortMessage) {
            if (parsedError instanceof viem_1.ContractFunctionRevertedError &&
                parsedError.data &&
                parsedError.data.errorName !== "Error") {
                const customErrorArgs = (_b = (_a = parsedError.data.args) === null || _a === void 0 ? void 0 : _a.toString()) !== null && _b !== void 0 ? _b : "";
                return `${parsedError.shortMessage.replace(/reverted\.$/, "reverted with the following reason:")}\n${parsedError.data.errorName}(${customErrorArgs})`;
            }
            return parsedError.shortMessage;
        }
        return (_d = (_c = parsedError.message) !== null && _c !== void 0 ? _c : parsedError.name) !== null && _d !== void 0 ? _d : "An unknown error occurred";
    }
    return (_e = parsedError === null || parsedError === void 0 ? void 0 : parsedError.message) !== null && _e !== void 0 ? _e : "An unknown error occurred";
};
exports.getParsedError = getParsedError;
