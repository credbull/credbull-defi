"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ContractVariables = void 0;
const DisplayVariable_1 = require("./DisplayVariable");
const ContractVariables = ({ refreshDisplayVariables, deployedContractData, }) => {
    if (!deployedContractData) {
        return null;
    }
    const functionsToDisplay = deployedContractData.abi.filter(part => part.type === "function")
        .filter(fn => {
        const isQueryableWithNoParams = (fn.stateMutability === "view" || fn.stateMutability === "pure") && fn.inputs.length === 0;
        return isQueryableWithNoParams;
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
        return <>No contract variables</>;
    }
    return (<>
      {functionsToDisplay.map(({ fn, inheritedFrom }) => (<DisplayVariable_1.DisplayVariable abi={deployedContractData.abi} abiFunction={fn} contractAddress={deployedContractData.address} key={fn.name} refreshDisplayVariables={refreshDisplayVariables} inheritedFrom={inheritedFrom}/>))}
    </>);
};
exports.ContractVariables = ContractVariables;
