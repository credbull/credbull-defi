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
exports.addIndexedArgsToEvent = exports.useScaffoldEventHistory = void 0;
const react_1 = require("react");
const useTargetNetwork_1 = require("./useTargetNetwork");
const react_query_1 = require("@tanstack/react-query");
const wagmi_1 = require("wagmi");
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
const common_1 = require("~~/utils/scaffold-eth/common");
const getEvents = (getLogsParams, publicClient, Options) => __awaiter(void 0, void 0, void 0, function* () {
    const logs = yield (publicClient === null || publicClient === void 0 ? void 0 : publicClient.getLogs({
        address: getLogsParams.address,
        fromBlock: getLogsParams.fromBlock,
        args: getLogsParams.args,
        event: getLogsParams.event,
    }));
    if (!logs)
        return undefined;
    const finalEvents = yield Promise.all(logs.map((log) => __awaiter(void 0, void 0, void 0, function* () {
        return Object.assign(Object.assign({}, log), { blockData: (Options === null || Options === void 0 ? void 0 : Options.blockData) && log.blockHash ? yield (publicClient === null || publicClient === void 0 ? void 0 : publicClient.getBlock({ blockHash: log.blockHash })) : null, transactionData: (Options === null || Options === void 0 ? void 0 : Options.transactionData) && log.transactionHash
                ? yield (publicClient === null || publicClient === void 0 ? void 0 : publicClient.getTransaction({ hash: log.transactionHash }))
                : null, receiptData: (Options === null || Options === void 0 ? void 0 : Options.receiptData) && log.transactionHash
                ? yield (publicClient === null || publicClient === void 0 ? void 0 : publicClient.getTransactionReceipt({ hash: log.transactionHash }))
                : null });
    })));
    return finalEvents;
});
/**
 * Reads events from a deployed contract
 * @param config - The config settings
 * @param config.contractName - deployed contract name
 * @param config.eventName - name of the event to listen for
 * @param config.fromBlock - the block number to start reading events from
 * @param config.filters - filters to be applied to the event (parameterName: value)
 * @param config.blockData - if set to true it will return the block data for each event (default: false)
 * @param config.transactionData - if set to true it will return the transaction data for each event (default: false)
 * @param config.receiptData - if set to true it will return the receipt data for each event (default: false)
 * @param config.watch - if set to true, the events will be updated every pollingInterval milliseconds set at scaffoldConfig (default: false)
 * @param config.enabled - set this to false to disable the hook from running (default: true)
 */
const useScaffoldEventHistory = ({ contractName, eventName, fromBlock, filters, blockData, transactionData, receiptData, watch, enabled = true, }) => {
    var _a;
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const publicClient = (0, wagmi_1.usePublicClient)({
        chainId: targetNetwork.id,
    });
    const [isFirstRender, setIsFirstRender] = (0, react_1.useState)(true);
    const { data: blockNumber } = (0, wagmi_1.useBlockNumber)({ watch: watch, chainId: targetNetwork.id });
    const { data: deployedContractData } = (0, scaffold_eth_1.useDeployedContractInfo)(contractName);
    const event = deployedContractData &&
        deployedContractData.abi.find(part => part.type === "event" && part.name === eventName);
    const isContractAddressAndClientReady = Boolean(deployedContractData === null || deployedContractData === void 0 ? void 0 : deployedContractData.address) && Boolean(publicClient);
    const query = (0, react_query_1.useInfiniteQuery)({
        queryKey: [
            "eventHistory",
            {
                contractName,
                address: deployedContractData === null || deployedContractData === void 0 ? void 0 : deployedContractData.address,
                eventName,
                fromBlock: fromBlock.toString(),
                chainId: targetNetwork.id,
                filters: JSON.stringify(filters, common_1.replacer),
            },
        ],
        queryFn: (_a) => __awaiter(void 0, [_a], void 0, function* ({ pageParam }) {
            if (!isContractAddressAndClientReady)
                return undefined;
            const data = yield getEvents({ address: deployedContractData === null || deployedContractData === void 0 ? void 0 : deployedContractData.address, event, fromBlock: pageParam, args: filters }, publicClient, { blockData, transactionData, receiptData });
            return data;
        }),
        enabled: enabled && isContractAddressAndClientReady,
        initialPageParam: fromBlock,
        getNextPageParam: () => {
            return blockNumber;
        },
        select: data => {
            const events = data.pages.flat();
            const eventHistoryData = events === null || events === void 0 ? void 0 : events.map(exports.addIndexedArgsToEvent);
            return {
                pages: eventHistoryData === null || eventHistoryData === void 0 ? void 0 : eventHistoryData.reverse(),
                pageParams: data.pageParams,
            };
        },
    });
    (0, react_1.useEffect)(() => {
        const shouldSkipEffect = !blockNumber || !watch || isFirstRender;
        if (shouldSkipEffect) {
            // skipping on first render, since on first render we should call queryFn with
            // fromBlock value, not blockNumber
            if (isFirstRender)
                setIsFirstRender(false);
            return;
        }
        query.fetchNextPage();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [blockNumber, watch]);
    return {
        data: (_a = query.data) === null || _a === void 0 ? void 0 : _a.pages,
        status: query.status,
        error: query.error,
        isLoading: query.isLoading,
        isFetchingNewEvent: query.isFetchingNextPage,
        refetch: query.refetch,
    };
};
exports.useScaffoldEventHistory = useScaffoldEventHistory;
const addIndexedArgsToEvent = (event) => {
    if (event.args && !Array.isArray(event.args)) {
        return Object.assign(Object.assign({}, event), { args: Object.assign(Object.assign({}, event.args), Object.values(event.args)) });
    }
    return event;
};
exports.addIndexedArgsToEvent = addIndexedArgsToEvent;
