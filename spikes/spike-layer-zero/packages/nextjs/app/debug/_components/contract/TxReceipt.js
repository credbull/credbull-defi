"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TxReceipt = void 0;
const react_1 = require("react");
const react_copy_to_clipboard_1 = require("react-copy-to-clipboard");
const outline_1 = require("@heroicons/react/24/outline");
const contract_1 = require("~~/app/debug/_components/contract");
const common_1 = require("~~/utils/scaffold-eth/common");
const TxReceipt = ({ txResult }) => {
    const [txResultCopied, setTxResultCopied] = (0, react_1.useState)(false);
    return (<div className="flex text-sm rounded-3xl peer-checked:rounded-b-none min-h-0 bg-secondary py-0">
      <div className="mt-1 pl-2">
        {txResultCopied ? (<outline_1.CheckCircleIcon className="ml-1.5 text-xl font-normal text-sky-600 h-5 w-5 cursor-pointer" aria-hidden="true"/>) : (<react_copy_to_clipboard_1.CopyToClipboard text={JSON.stringify(txResult, common_1.replacer, 2)} onCopy={() => {
                setTxResultCopied(true);
                setTimeout(() => {
                    setTxResultCopied(false);
                }, 800);
            }}>
            <outline_1.DocumentDuplicateIcon className="ml-1.5 text-xl font-normal text-sky-600 h-5 w-5 cursor-pointer" aria-hidden="true"/>
          </react_copy_to_clipboard_1.CopyToClipboard>)}
      </div>
      <div className="flex-wrap collapse collapse-arrow">
        <input type="checkbox" className="min-h-0 peer"/>
        <div className="collapse-title text-sm min-h-0 py-1.5 pl-1">
          <strong>Transaction Receipt</strong>
        </div>
        <div className="collapse-content overflow-auto bg-secondary rounded-t-none rounded-3xl !pl-0">
          <pre className="text-xs">
            {Object.entries(txResult).map(([k, v]) => (<contract_1.ObjectFieldDisplay name={k} value={v} size="xs" leftPad={false} key={k}/>))}
          </pre>
        </div>
      </div>
    </div>);
};
exports.TxReceipt = TxReceipt;
