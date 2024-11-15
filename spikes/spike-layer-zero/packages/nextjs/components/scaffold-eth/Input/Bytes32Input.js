"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Bytes32Input = void 0;
const react_1 = require("react");
const viem_1 = require("viem");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const Bytes32Input = ({ value, onChange, name, placeholder, disabled }) => {
    const convertStringToBytes32 = (0, react_1.useCallback)(() => {
        if (!value) {
            return;
        }
        onChange((0, viem_1.isHex)(value) ? (0, viem_1.hexToString)(value, { size: 32 }) : (0, viem_1.stringToHex)(value, { size: 32 }));
    }, [onChange, value]);
    return (<scaffold_eth_1.InputBase name={name} value={value} placeholder={placeholder} onChange={onChange} disabled={disabled} suffix={<div className="self-center cursor-pointer text-xl font-semibold px-4 text-accent" onClick={convertStringToBytes32}>
          #
        </div>}/>);
};
exports.Bytes32Input = Bytes32Input;
