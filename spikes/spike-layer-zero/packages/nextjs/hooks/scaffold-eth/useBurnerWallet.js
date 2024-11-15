"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useBurnerWallet = exports.loadBurnerSK = exports.saveBurnerSK = void 0;
const react_1 = require("react");
const useTargetNetwork_1 = require("./useTargetNetwork");
const usehooks_ts_1 = require("usehooks-ts");
const viem_1 = require("viem");
const accounts_1 = require("viem/accounts");
const wagmi_1 = require("wagmi");
const burnerStorageKey = "scaffoldEth2.burnerWallet.sk";
/**
 * Checks if the private key is valid
 */
const isValidSk = (pk) => {
    return (pk === null || pk === void 0 ? void 0 : pk.length) === 64 || (pk === null || pk === void 0 ? void 0 : pk.length) === 66;
};
/**
 * If no burner is found in localstorage, we will generate a random private key
 */
const newDefaultPrivateKey = (0, accounts_1.generatePrivateKey)();
/**
 * Save the current burner private key to local storage
 */
const saveBurnerSK = (privateKey) => {
    var _a;
    if (typeof window != "undefined" && window != null) {
        (_a = window === null || window === void 0 ? void 0 : window.localStorage) === null || _a === void 0 ? void 0 : _a.setItem(burnerStorageKey, privateKey);
    }
};
exports.saveBurnerSK = saveBurnerSK;
/**
 * Gets the current burner private key from local storage
 */
const loadBurnerSK = () => {
    var _a, _b, _c, _d;
    let currentSk = "0x";
    if (typeof window != "undefined" && window != null) {
        currentSk = ((_d = (_c = (_b = (_a = window === null || window === void 0 ? void 0 : window.localStorage) === null || _a === void 0 ? void 0 : _a.getItem) === null || _b === void 0 ? void 0 : _b.call(_a, burnerStorageKey)) === null || _c === void 0 ? void 0 : _c.replaceAll('"', "")) !== null && _d !== void 0 ? _d : "0x");
    }
    if (!!currentSk && isValidSk(currentSk)) {
        return currentSk;
    }
    else {
        (0, exports.saveBurnerSK)(newDefaultPrivateKey);
        return newDefaultPrivateKey;
    }
};
exports.loadBurnerSK = loadBurnerSK;
/**
 * Creates a burner wallet
 */
const useBurnerWallet = () => {
    const [burnerSk, setBurnerSk] = (0, usehooks_ts_1.useLocalStorage)(burnerStorageKey, newDefaultPrivateKey, {
        initializeWithValue: false,
    });
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const publicClient = (0, wagmi_1.usePublicClient)({ chainId: targetNetwork.id });
    const [walletClient, setWalletClient] = (0, react_1.useState)();
    const [generatedPrivateKey, setGeneratedPrivateKey] = (0, react_1.useState)("0x");
    const [account, setAccount] = (0, react_1.useState)();
    const isCreatingNewBurnerRef = (0, react_1.useRef)(false);
    const saveBurner = (0, react_1.useCallback)(() => {
        setBurnerSk(generatedPrivateKey);
    }, [setBurnerSk, generatedPrivateKey]);
    const generateNewBurner = (0, react_1.useCallback)(() => {
        if (publicClient && !isCreatingNewBurnerRef.current) {
            console.log("🔑 Create new burner wallet...");
            isCreatingNewBurnerRef.current = true;
            const randomPrivateKey = (0, accounts_1.generatePrivateKey)();
            const randomAccount = (0, accounts_1.privateKeyToAccount)(randomPrivateKey);
            const client = (0, viem_1.createWalletClient)({
                chain: publicClient.chain,
                account: randomAccount,
                transport: (0, viem_1.http)(),
            });
            setWalletClient(client);
            setGeneratedPrivateKey(randomPrivateKey);
            setAccount(randomAccount);
            setBurnerSk(() => {
                console.log("🔥 Saving new burner wallet");
                isCreatingNewBurnerRef.current = false;
                return randomPrivateKey;
            });
            return client;
        }
        else {
            console.log("⚠ Could not create burner wallet");
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [publicClient === null || publicClient === void 0 ? void 0 : publicClient.chain.id]);
    /**
     * Load wallet with burnerSk
     * connect and set wallet, once we have burnerSk and valid provider
     */
    (0, react_1.useEffect)(() => {
        if (burnerSk && (publicClient === null || publicClient === void 0 ? void 0 : publicClient.chain.id)) {
            let wallet = undefined;
            if (isValidSk(burnerSk)) {
                const randomAccount = (0, accounts_1.privateKeyToAccount)(burnerSk);
                wallet = (0, viem_1.createWalletClient)({
                    chain: publicClient.chain,
                    account: randomAccount,
                    transport: (0, viem_1.http)(),
                });
                setGeneratedPrivateKey(burnerSk);
                setAccount(randomAccount);
            }
            else {
                wallet = generateNewBurner();
            }
            if (wallet == null) {
                throw "Error:  Could not create burner wallet";
            }
            setWalletClient(wallet);
            saveBurner();
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [burnerSk, publicClient === null || publicClient === void 0 ? void 0 : publicClient.chain.id]);
    return {
        walletClient,
        account,
        generateNewBurner,
        saveBurner,
    };
};
exports.useBurnerWallet = useBurnerWallet;
