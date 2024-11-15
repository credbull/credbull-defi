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
exports.useScaffoldWriteContract = void 0;
const react_1 = require("react");
const useTargetNetwork_1 = require("./useTargetNetwork");
const wagmi_1 = require("wagmi");
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
const scaffold_eth_2 = require("~~/utils/scaffold-eth");
/**
 * Wrapper around wagmi's useWriteContract hook which automatically loads (by name) the contract ABI and address from
 * the contracts present in deployedContracts.ts & externalContracts.ts corresponding to targetNetworks configured in scaffold.config.ts
 * @param contractName - name of the contract to be written to
 * @param writeContractParams - wagmi's useWriteContract parameters
 */
const useScaffoldWriteContract = (contractName, writeContractParams) => {
    const { chain } = (0, wagmi_1.useAccount)();
    const writeTx = (0, scaffold_eth_1.useTransactor)();
    const [isMining, setIsMining] = (0, react_1.useState)(false);
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const wagmiContractWrite = (0, wagmi_1.useWriteContract)(writeContractParams);
    const { data: deployedContractData } = (0, scaffold_eth_1.useDeployedContractInfo)(contractName);
    const sendContractWriteAsyncTx = (variables, options) => __awaiter(void 0, void 0, void 0, function* () {
        if (!deployedContractData) {
            scaffold_eth_2.notification.error("Target Contract is not deployed, did you forget to run `yarn deploy`?");
            return;
        }
        if (!(chain === null || chain === void 0 ? void 0 : chain.id)) {
            scaffold_eth_2.notification.error("Please connect your wallet");
            return;
        }
        if ((chain === null || chain === void 0 ? void 0 : chain.id) !== targetNetwork.id) {
            scaffold_eth_2.notification.error("You are on the wrong network");
            return;
        }
        try {
            setIsMining(true);
            const _a = options || {}, { blockConfirmations, onBlockConfirmation } = _a, mutateOptions = __rest(_a, ["blockConfirmations", "onBlockConfirmation"]);
            const makeWriteWithParams = () => wagmiContractWrite.writeContractAsync(Object.assign({ abi: deployedContractData.abi, address: deployedContractData.address }, variables), mutateOptions);
            const writeTxResult = yield writeTx(makeWriteWithParams, { blockConfirmations, onBlockConfirmation });
            return writeTxResult;
        }
        catch (e) {
            throw e;
        }
        finally {
            setIsMining(false);
        }
    });
    const sendContractWriteTx = (variables, options) => {
        if (!deployedContractData) {
            scaffold_eth_2.notification.error("Target Contract is not deployed, did you forget to run `yarn deploy`?");
            return;
        }
        if (!(chain === null || chain === void 0 ? void 0 : chain.id)) {
            scaffold_eth_2.notification.error("Please connect your wallet");
            return;
        }
        if ((chain === null || chain === void 0 ? void 0 : chain.id) !== targetNetwork.id) {
            scaffold_eth_2.notification.error("You are on the wrong network");
            return;
        }
        wagmiContractWrite.writeContract(Object.assign({ abi: deployedContractData.abi, address: deployedContractData.address }, variables), options);
    };
    return Object.assign(Object.assign({}, wagmiContractWrite), { isMining, 
        // Overwrite wagmi's writeContactAsync
        writeContractAsync: sendContractWriteAsyncTx, 
        // Overwrite wagmi's writeContract
        writeContract: sendContractWriteTx });
};
exports.useScaffoldWriteContract = useScaffoldWriteContract;
