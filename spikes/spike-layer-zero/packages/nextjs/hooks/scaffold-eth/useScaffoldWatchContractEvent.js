"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useScaffoldWatchContractEvent = void 0;
const useTargetNetwork_1 = require("./useTargetNetwork");
const wagmi_1 = require("wagmi");
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
/**
 * Wrapper around wagmi's useEventSubscriber hook which automatically loads (by name) the contract ABI and
 * address from the contracts present in deployedContracts.ts & externalContracts.ts
 * @param config - The config settings
 * @param config.contractName - deployed contract name
 * @param config.eventName - name of the event to listen for
 * @param config.onLogs - the callback that receives events.
 */
const useScaffoldWatchContractEvent = ({ contractName, eventName, onLogs, }) => {
    const { data: deployedContractData } = (0, scaffold_eth_1.useDeployedContractInfo)(contractName);
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const addIndexedArgsToLogs = (logs) => logs.map(scaffold_eth_1.addIndexedArgsToEvent);
    const listenerWithIndexedArgs = (logs) => onLogs(addIndexedArgsToLogs(logs));
    return (0, wagmi_1.useWatchContractEvent)({
        address: deployedContractData === null || deployedContractData === void 0 ? void 0 : deployedContractData.address,
        abi: deployedContractData === null || deployedContractData === void 0 ? void 0 : deployedContractData.abi,
        chainId: targetNetwork.id,
        onLogs: listenerWithIndexedArgs,
        eventName,
    });
};
exports.useScaffoldWatchContractEvent = useScaffoldWatchContractEvent;
