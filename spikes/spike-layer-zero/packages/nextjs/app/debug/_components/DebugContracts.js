"use strict";
"use client";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DebugContracts = DebugContracts;
const react_1 = require("react");
const usehooks_ts_1 = require("usehooks-ts");
const solid_1 = require("@heroicons/react/20/solid");
const contract_1 = require("~~/app/debug/_components/contract");
const contractsData_1 = require("~~/utils/scaffold-eth/contractsData");
const selectedContractStorageKey = "scaffoldEth2.selectedContract";
function DebugContracts() {
    const contractsData = (0, contractsData_1.useAllContracts)();
    const contractNames = (0, react_1.useMemo)(() => Object.keys(contractsData), [contractsData]);
    const [selectedContract, setSelectedContract] = (0, usehooks_ts_1.useLocalStorage)(selectedContractStorageKey, contractNames[0], { initializeWithValue: false });
    (0, react_1.useEffect)(() => {
        if (!contractNames.includes(selectedContract)) {
            setSelectedContract(contractNames[0]);
        }
    }, [contractNames, selectedContract, setSelectedContract]);
    return (<div className="flex flex-col gap-y-6 lg:gap-y-8 py-8 lg:py-12 justify-center items-center">
      {contractNames.length === 0 ? (<p className="text-3xl mt-14">No contracts found!</p>) : (<>
          {contractNames.length > 1 && (<div className="flex flex-row gap-2 w-full max-w-7xl pb-1 px-6 lg:px-10 flex-wrap">
              {contractNames.map(contractName => {
                    var _a;
                    return (<button className={`btn btn-secondary btn-sm font-light hover:border-transparent ${contractName === selectedContract
                            ? "bg-base-300 hover:bg-base-300 no-animation"
                            : "bg-base-100 hover:bg-secondary"}`} key={contractName} onClick={() => setSelectedContract(contractName)}>
                  {contractName}
                  {((_a = contractsData[contractName]) === null || _a === void 0 ? void 0 : _a.external) && (<span className="tooltip tooltip-top tooltip-accent" data-tip="External contract">
                      <solid_1.BarsArrowUpIcon className="h-4 w-4 cursor-pointer"/>
                    </span>)}
                </button>);
                })}
            </div>)}
          {contractNames.map(contractName => (<contract_1.ContractUI key={contractName} contractName={contractName} className={contractName === selectedContract ? "" : "hidden"}/>))}
        </>)}
    </div>);
}
