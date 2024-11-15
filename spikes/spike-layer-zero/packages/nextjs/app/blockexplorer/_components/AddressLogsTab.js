"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddressLogsTab = void 0;
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
const common_1 = require("~~/utils/scaffold-eth/common");
const AddressLogsTab = ({ address }) => {
    const contractLogs = (0, scaffold_eth_1.useContractLogs)(address);
    return (<div className="flex flex-col gap-3 p-4">
      <div className="mockup-code overflow-auto max-h-[500px]">
        <pre className="px-5 whitespace-pre-wrap break-words">
          {contractLogs.map((log, i) => (<div key={i}>
              <strong>Log:</strong> {JSON.stringify(log, common_1.replacer, 2)}
            </div>))}
        </pre>
      </div>
    </div>);
};
exports.AddressLogsTab = AddressLogsTab;
