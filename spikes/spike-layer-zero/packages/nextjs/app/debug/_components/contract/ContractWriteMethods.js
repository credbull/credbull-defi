"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ContractWriteMethods = void 0;
const contract_1 = require("~~/app/debug/_components/contract");
const ContractWriteMethods = ({ onChange, deployedContractData, }) => {
    if (!deployedContractData) {
        return null;
    }
    const functionsToDisplay = deployedContractData.abi.filter(part => part.type === "function")
        .filter(fn => {
        const isWriteableFunction = fn.stateMutability !== "view" && fn.stateMutability !== "pure";
        return isWriteableFunction;
    })
        .map(fn => {
        var _a;
        return {
            fn,
            inheritedFrom: (_a = deployedContractData === null || deployedContractData === void 0 ? void 0 : deployedContractData.inheritedFunctions) === null || _a === void 0 ? void 0 : _a[fn.name],
        };
    })
        .sort((a, b) => (b.inheritedFrom ? b.inheritedFrom.localeCompare(a.inheritedFrom) : 1));
    if (!functionsToDisplay.length) {
        return <>No write methods</>;
    }
    return (<>
      {functionsToDisplay.map(({ fn, inheritedFrom }, idx) => (<contract_1.WriteOnlyFunctionForm abi={deployedContractData.abi} key={`${fn.name}-${idx}}`} abiFunction={fn} onChange={onChange} contractAddress={deployedContractData.address} inheritedFrom={inheritedFrom}/>))}
    </>);
};
exports.ContractWriteMethods = ContractWriteMethods;
