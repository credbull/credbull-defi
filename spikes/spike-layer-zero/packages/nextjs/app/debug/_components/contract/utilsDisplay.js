"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ObjectFieldDisplay = exports.displayTxResult = void 0;
const react_1 = require("react");
const viem_1 = require("viem");
const solid_1 = require("@heroicons/react/24/solid");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const common_1 = require("~~/utils/scaffold-eth/common");
const displayTxResult = (displayContent, fontSize = "base") => {
    if (displayContent == null) {
        return "";
    }
    if (typeof displayContent === "bigint") {
        return <NumberDisplay value={displayContent}/>;
    }
    if (typeof displayContent === "string") {
        if ((0, viem_1.isAddress)(displayContent)) {
            return <scaffold_eth_1.Address address={displayContent} size={fontSize}/>;
        }
        if ((0, viem_1.isHex)(displayContent)) {
            return displayContent; // don't add quotes
        }
    }
    if (Array.isArray(displayContent)) {
        return <ArrayDisplay values={displayContent} size={fontSize}/>;
    }
    if (typeof displayContent === "object") {
        return <StructDisplay struct={displayContent} size={fontSize}/>;
    }
    return JSON.stringify(displayContent, common_1.replacer, 2);
};
exports.displayTxResult = displayTxResult;
const NumberDisplay = ({ value }) => {
    const [isEther, setIsEther] = (0, react_1.useState)(false);
    const asNumber = Number(value);
    if (asNumber <= Number.MAX_SAFE_INTEGER && asNumber >= Number.MIN_SAFE_INTEGER) {
        return String(value);
    }
    return (<div className="flex items-baseline">
      {isEther ? "Ξ" + (0, viem_1.formatEther)(value) : String(value)}
      <span className="tooltip tooltip-secondary font-sans ml-2" data-tip={isEther ? "Multiply by 1e18" : "Divide by 1e18"}>
        <button className="btn btn-ghost btn-circle btn-xs" onClick={() => setIsEther(!isEther)}>
          <solid_1.ArrowsRightLeftIcon className="h-3 w-3 opacity-65"/>
        </button>
      </span>
    </div>);
};
const ObjectFieldDisplay = ({ name, value, size, leftPad = true, }) => {
    return (<div className={`flex flex-row items-baseline ${leftPad ? "ml-4" : ""}`}>
      <span className="text-gray-500 dark:text-gray-400 mr-2">{name}:</span>
      <span className="text-base-content">{(0, exports.displayTxResult)(value, size)}</span>
    </div>);
};
exports.ObjectFieldDisplay = ObjectFieldDisplay;
const ArrayDisplay = ({ values, size }) => {
    return (<div className="flex flex-col gap-y-1">
      {values.length ? "array" : "[]"}
      {values.map((v, i) => (<exports.ObjectFieldDisplay key={i} name={`[${i}]`} value={v} size={size}/>))}
    </div>);
};
const StructDisplay = ({ struct, size }) => {
    return (<div className="flex flex-col gap-y-1">
      struct
      {Object.entries(struct).map(([k, v]) => (<exports.ObjectFieldDisplay key={k} name={k} value={v} size={size}/>))}
    </div>);
};
