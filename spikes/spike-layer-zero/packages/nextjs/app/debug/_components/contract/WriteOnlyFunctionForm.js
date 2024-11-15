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
exports.WriteOnlyFunctionForm = void 0;
const react_1 = require("react");
const InheritanceTooltip_1 = require("./InheritanceTooltip");
const wagmi_1 = require("wagmi");
const contract_1 = require("~~/app/debug/_components/contract");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const scaffold_eth_2 = require("~~/hooks/scaffold-eth");
const useTargetNetwork_1 = require("~~/hooks/scaffold-eth/useTargetNetwork");
const WriteOnlyFunctionForm = ({ abi, abiFunction, onChange, contractAddress, inheritedFrom, }) => {
    const [form, setForm] = (0, react_1.useState)(() => (0, contract_1.getInitialFormState)(abiFunction));
    const [txValue, setTxValue] = (0, react_1.useState)("");
    const { chain } = (0, wagmi_1.useAccount)();
    const writeTxn = (0, scaffold_eth_2.useTransactor)();
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const writeDisabled = !chain || (chain === null || chain === void 0 ? void 0 : chain.id) !== targetNetwork.id;
    const { data: result, isPending, writeContractAsync } = (0, wagmi_1.useWriteContract)();
    const handleWrite = () => __awaiter(void 0, void 0, void 0, function* () {
        if (writeContractAsync) {
            try {
                const makeWriteWithParams = () => writeContractAsync({
                    address: contractAddress,
                    functionName: abiFunction.name,
                    abi: abi,
                    args: (0, contract_1.getParsedContractFunctionArgs)(form),
                    value: BigInt(txValue),
                });
                yield writeTxn(makeWriteWithParams);
                onChange();
            }
            catch (e) {
                console.error("⚡️ ~ file: WriteOnlyFunctionForm.tsx:handleWrite ~ error", e);
            }
        }
    });
    const [displayedTxResult, setDisplayedTxResult] = (0, react_1.useState)();
    const { data: txResult } = (0, wagmi_1.useWaitForTransactionReceipt)({
        hash: result,
    });
    (0, react_1.useEffect)(() => {
        setDisplayedTxResult(txResult);
    }, [txResult]);
    // TODO use `useMemo` to optimize also update in ReadOnlyFunctionForm
    const transformedFunction = (0, contract_1.transformAbiFunction)(abiFunction);
    const inputs = transformedFunction.inputs.map((input, inputIndex) => {
        const key = (0, contract_1.getFunctionInputKey)(abiFunction.name, input, inputIndex);
        return (<contract_1.ContractInput key={key} setForm={updatedFormValue => {
                setDisplayedTxResult(undefined);
                setForm(updatedFormValue);
            }} form={form} stateObjectKey={key} paramType={input}/>);
    });
    const zeroInputs = inputs.length === 0 && abiFunction.stateMutability !== "payable";
    return (<div className="py-5 space-y-3 first:pt-0 last:pb-1">
      <div className={`flex gap-3 ${zeroInputs ? "flex-row justify-between items-center" : "flex-col"}`}>
        <p className="font-medium my-0 break-words">
          {abiFunction.name}
          <InheritanceTooltip_1.InheritanceTooltip inheritedFrom={inheritedFrom}/>
        </p>
        {inputs}
        {abiFunction.stateMutability === "payable" ? (<div className="flex flex-col gap-1.5 w-full">
            <div className="flex items-center ml-2">
              <span className="text-xs font-medium mr-2 leading-none">payable value</span>
              <span className="block text-xs font-extralight leading-none">wei</span>
            </div>
            <scaffold_eth_1.IntegerInput value={txValue} onChange={updatedTxValue => {
                setDisplayedTxResult(undefined);
                setTxValue(updatedTxValue);
            }} placeholder="value (wei)"/>
          </div>) : null}
        <div className="flex justify-between gap-2">
          {!zeroInputs && (<div className="flex-grow basis-0">
              {displayedTxResult ? <contract_1.TxReceipt txResult={displayedTxResult}/> : null}
            </div>)}
          <div className={`flex ${writeDisabled &&
            "tooltip before:content-[attr(data-tip)] before:right-[-10px] before:left-auto before:transform-none"}`} data-tip={`${writeDisabled && "Wallet not connected or in the wrong network"}`}>
            <button className="btn btn-secondary btn-sm" disabled={writeDisabled || isPending} onClick={handleWrite}>
              {isPending && <span className="loading loading-spinner loading-xs"></span>}
              Send 💸
            </button>
          </div>
        </div>
      </div>
      {zeroInputs && txResult ? (<div className="flex-grow basis-0">
          <contract_1.TxReceipt txResult={txResult}/>
        </div>) : null}
    </div>);
};
exports.WriteOnlyFunctionForm = WriteOnlyFunctionForm;
