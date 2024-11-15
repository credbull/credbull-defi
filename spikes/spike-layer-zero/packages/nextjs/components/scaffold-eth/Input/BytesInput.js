"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BytesInput = void 0;
const react_1 = require("react");
const viem_1 = require("viem");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const BytesInput = ({ value, onChange, name, placeholder, disabled }) => {
    const convertStringToBytes = (0, react_1.useCallback)(() => {
        onChange((0, viem_1.isHex)(value) ? (0, viem_1.bytesToString)((0, viem_1.toBytes)(value)) : (0, viem_1.toHex)((0, viem_1.toBytes)(value)));
    }, [onChange, value]);
    return (<scaffold_eth_1.InputBase name={name} value={value} placeholder={placeholder} onChange={onChange} disabled={disabled} suffix={<div className="self-center cursor-pointer text-xl font-semibold px-4 text-accent" onClick={convertStringToBytes}>
          #
        </div>}/>);
};
exports.BytesInput = BytesInput;
