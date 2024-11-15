"use strict";
"use client";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReadOnlyFunctionForm = void 0;
const react_1 = require("react");
const InheritanceTooltip_1 = require("./InheritanceTooltip");
const wagmi_1 = require("wagmi");
const contract_1 = require("~~/app/debug/_components/contract");
const useTargetNetwork_1 = require("~~/hooks/scaffold-eth/useTargetNetwork");
const scaffold_eth_1 = require("~~/utils/scaffold-eth");
const ReadOnlyFunctionForm = ({ contractAddress, abiFunction, inheritedFrom, abi, }) => {
    const [form, setForm] = (0, react_1.useState)(() => (0, contract_1.getInitialFormState)(abiFunction));
    const [result, setResult] = (0, react_1.useState)();
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const { isFetching, refetch, error } = (0, wagmi_1.useReadContract)({
        address: contractAddress,
        functionName: abiFunction.name,
        abi: abi,
        args: (0, contract_1.getParsedContractFunctionArgs)(form),
        chainId: targetNetwork.id,
        query: {
            enabled: false,
            retry: false,
        },
    });
    (0, react_1.useEffect)(() => {
        if (error) {
            const parsedError = (0, scaffold_eth_1.getParsedError)(error);
            scaffold_eth_1.notification.error(parsedError);
        }
    }, [error]);
    const transformedFunction = (0, contract_1.transformAbiFunction)(abiFunction);
    const inputElements = transformedFunction.inputs.map((input, inputIndex) => {
        const key = (0, contract_1.getFunctionInputKey)(abiFunction.name, input, inputIndex);
        return (<contract_1.ContractInput key={key} setForm={updatedFormValue => {
                setResult(undefined);
                setForm(updatedFormValue);
            }} form={form} stateObjectKey={key} paramType={input}/>);
    });
    return (<div className="flex flex-col gap-3 py-5 first:pt-0 last:pb-1">
      <p className="font-medium my-0 break-words">
        {abiFunction.name}
        <InheritanceTooltip_1.InheritanceTooltip inheritedFrom={inheritedFrom}/>
      </p>
      {inputElements}
      <div className="flex flex-col md:flex-row justify-between gap-2 flex-wrap">
        <div className="flex-grow w-full md:max-w-[80%]">
          {result !== null && result !== undefined && (<div className="bg-secondary rounded-3xl text-sm px-4 py-1.5 break-words overflow-auto">
              <p className="font-bold m-0 mb-1">Result:</p>
              <pre className="whitespace-pre-wrap break-words">{(0, contract_1.displayTxResult)(result, "sm")}</pre>
            </div>)}
        </div>
        <button className="btn btn-secondary btn-sm self-end md:self-start" onClick={() => __awaiter(void 0, void 0, void 0, function* () {
            const { data } = yield refetch();
            setResult(data);
        })} disabled={isFetching}>
          {isFetching && <span className="loading loading-spinner loading-xs"></span>}
          Read 📡
        </button>
      </div>
    </div>);
};
exports.ReadOnlyFunctionForm = ReadOnlyFunctionForm;
