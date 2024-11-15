"use strict";
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.useScaffoldReadContract = void 0;
const react_1 = require("react");
const useTargetNetwork_1 = require("./useTargetNetwork");
const react_query_1 = require("@tanstack/react-query");
const wagmi_1 = require("wagmi");
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
/**
 * Wrapper around wagmi's useContractRead hook which automatically loads (by name) the contract ABI and address from
 * the contracts present in deployedContracts.ts & externalContracts.ts corresponding to targetNetworks configured in scaffold.config.ts
 * @param config - The config settings, including extra wagmi configuration
 * @param config.contractName - deployed contract name
 * @param config.functionName - name of the function to be called
 * @param config.args - args to be passed to the function call
 */
const useScaffoldReadContract = (_a) => {
    var { contractName, functionName, args } = _a, readConfig = __rest(_a, ["contractName", "functionName", "args"]);
    const { data: deployedContract } = (0, scaffold_eth_1.useDeployedContractInfo)(contractName);
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const { query: queryOptions, watch } = readConfig, readContractConfig = __rest(readConfig, ["query", "watch"]);
    // set watch to true by default
    const defaultWatch = watch !== null && watch !== void 0 ? watch : true;
    const readContractHookRes = (0, wagmi_1.useReadContract)(Object.assign(Object.assign({ chainId: targetNetwork.id, functionName, address: deployedContract === null || deployedContract === void 0 ? void 0 : deployedContract.address, abi: deployedContract === null || deployedContract === void 0 ? void 0 : deployedContract.abi, args }, readContractConfig), { query: Object.assign({ enabled: !Array.isArray(args) || !args.some(arg => arg === undefined) }, queryOptions) }));
    const queryClient = (0, react_query_1.useQueryClient)();
    const { data: blockNumber } = (0, wagmi_1.useBlockNumber)({
        watch: defaultWatch,
        chainId: targetNetwork.id,
        query: {
            enabled: defaultWatch,
        },
    });
    (0, react_1.useEffect)(() => {
        if (defaultWatch) {
            queryClient.invalidateQueries({ queryKey: readContractHookRes.queryKey });
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [blockNumber]);
    return readContractHookRes;
};
exports.useScaffoldReadContract = useScaffoldReadContract;
