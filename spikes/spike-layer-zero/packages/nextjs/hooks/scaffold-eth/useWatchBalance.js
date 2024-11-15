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
exports.useWatchBalance = void 0;
const react_1 = require("react");
const useTargetNetwork_1 = require("./useTargetNetwork");
const react_query_1 = require("@tanstack/react-query");
const wagmi_1 = require("wagmi");
/**
 * Wrapper around wagmi's useBalance hook. Updates data on every block change.
 */
const useWatchBalance = (useBalanceParameters) => {
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const queryClient = (0, react_query_1.useQueryClient)();
    const { data: blockNumber } = (0, wagmi_1.useBlockNumber)({ watch: true, chainId: targetNetwork.id });
    const _a = (0, wagmi_1.useBalance)(useBalanceParameters), { queryKey } = _a, restUseBalanceReturn = __rest(_a, ["queryKey"]);
    (0, react_1.useEffect)(() => {
        queryClient.invalidateQueries({ queryKey });
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [blockNumber]);
    return restUseBalanceReturn;
};
exports.useWatchBalance = useWatchBalance;
