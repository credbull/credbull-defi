"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.useTargetNetwork = useTargetNetwork;
const react_1 = require("react");
const wagmi_1 = require("wagmi");
const scaffold_config_1 = __importDefault(require("~~/scaffold.config"));
const store_1 = require("~~/services/store/store");
const scaffold_eth_1 = require("~~/utils/scaffold-eth");
/**
 * Retrieves the connected wallet's network from scaffold.config or defaults to the 0th network in the list if the wallet is not connected.
 */
function useTargetNetwork() {
    const { chain } = (0, wagmi_1.useAccount)();
    const targetNetwork = (0, store_1.useGlobalState)(({ targetNetwork }) => targetNetwork);
    const setTargetNetwork = (0, store_1.useGlobalState)(({ setTargetNetwork }) => setTargetNetwork);
    (0, react_1.useEffect)(() => {
        const newSelectedNetwork = scaffold_config_1.default.targetNetworks.find(targetNetwork => targetNetwork.id === (chain === null || chain === void 0 ? void 0 : chain.id));
        if (newSelectedNetwork && newSelectedNetwork.id !== targetNetwork.id) {
            setTargetNetwork(newSelectedNetwork);
        }
    }, [chain === null || chain === void 0 ? void 0 : chain.id, setTargetNetwork, targetNetwork.id]);
    return (0, react_1.useMemo)(() => ({
        targetNetwork: Object.assign(Object.assign({}, targetNetwork), scaffold_eth_1.NETWORKS_EXTRA_DATA[targetNetwork.id]),
    }), [targetNetwork]);
}
