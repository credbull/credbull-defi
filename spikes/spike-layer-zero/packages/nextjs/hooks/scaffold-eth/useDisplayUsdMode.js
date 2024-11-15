"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useDisplayUsdMode = void 0;
const react_1 = require("react");
const store_1 = require("~~/services/store/store");
const useDisplayUsdMode = ({ defaultUsdMode = false }) => {
    const nativeCurrencyPrice = (0, store_1.useGlobalState)(state => state.nativeCurrency.price);
    const isPriceFetched = nativeCurrencyPrice > 0;
    const predefinedUsdMode = isPriceFetched ? Boolean(defaultUsdMode) : false;
    const [displayUsdMode, setDisplayUsdMode] = (0, react_1.useState)(predefinedUsdMode);
    (0, react_1.useEffect)(() => {
        setDisplayUsdMode(predefinedUsdMode);
    }, [predefinedUsdMode]);
    const toggleDisplayUsdMode = (0, react_1.useCallback)(() => {
        if (isPriceFetched) {
            setDisplayUsdMode(!displayUsdMode);
        }
    }, [displayUsdMode, isPriceFetched]);
    return { displayUsdMode, toggleDisplayUsdMode };
};
exports.useDisplayUsdMode = useDisplayUsdMode;
