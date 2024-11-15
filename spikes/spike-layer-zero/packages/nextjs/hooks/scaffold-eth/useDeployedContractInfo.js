"use strict";
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
exports.useDeployedContractInfo = void 0;
const react_1 = require("react");
const useTargetNetwork_1 = require("./useTargetNetwork");
const usehooks_ts_1 = require("usehooks-ts");
const wagmi_1 = require("wagmi");
const contract_1 = require("~~/utils/scaffold-eth/contract");
/**
 * Gets the matching contract info for the provided contract name from the contracts present in deployedContracts.ts
 * and externalContracts.ts corresponding to targetNetworks configured in scaffold.config.ts
 */
const useDeployedContractInfo = (contractName) => {
    var _a;
    const isMounted = (0, usehooks_ts_1.useIsMounted)();
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const deployedContract = (_a = contract_1.contracts === null || contract_1.contracts === void 0 ? void 0 : contract_1.contracts[targetNetwork.id]) === null || _a === void 0 ? void 0 : _a[contractName];
    const [status, setStatus] = (0, react_1.useState)(contract_1.ContractCodeStatus.LOADING);
    const publicClient = (0, wagmi_1.usePublicClient)({ chainId: targetNetwork.id });
    (0, react_1.useEffect)(() => {
        const checkContractDeployment = () => __awaiter(void 0, void 0, void 0, function* () {
            try {
                if (!isMounted() || !publicClient)
                    return;
                if (!deployedContract) {
                    setStatus(contract_1.ContractCodeStatus.NOT_FOUND);
                    return;
                }
                const code = yield publicClient.getBytecode({
                    address: deployedContract.address,
                });
                // If contract code is `0x` => no contract deployed on that address
                if (code === "0x") {
                    setStatus(contract_1.ContractCodeStatus.NOT_FOUND);
                    return;
                }
                setStatus(contract_1.ContractCodeStatus.DEPLOYED);
            }
            catch (e) {
                console.error(e);
                setStatus(contract_1.ContractCodeStatus.NOT_FOUND);
            }
        });
        checkContractDeployment();
    }, [isMounted, contractName, deployedContract, publicClient]);
    return {
        data: status === contract_1.ContractCodeStatus.DEPLOYED ? deployedContract : undefined,
        isLoading: status === contract_1.ContractCodeStatus.LOADING,
    };
};
exports.useDeployedContractInfo = useDeployedContractInfo;
