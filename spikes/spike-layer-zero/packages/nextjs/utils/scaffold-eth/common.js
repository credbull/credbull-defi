"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isZeroAddress = exports.ZERO_ADDRESS = exports.replacer = void 0;
// To be used in JSON.stringify when a field might be bigint
// https://wagmi.sh/react/faq#bigint-serialization
const replacer = (_key, value) => (typeof value === "bigint" ? value.toString() : value);
exports.replacer = replacer;
exports.ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const isZeroAddress = (address) => address === exports.ZERO_ADDRESS;
exports.isZeroAddress = isZeroAddress;
