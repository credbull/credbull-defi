"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddressInput = void 0;
const react_1 = require("react");
const blo_1 = require("blo");
const usehooks_ts_1 = require("usehooks-ts");
const viem_1 = require("viem");
const ens_1 = require("viem/ens");
const wagmi_1 = require("wagmi");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
/**
 * Address input with ENS name resolution
 */
const AddressInput = ({ value, name, placeholder, onChange, disabled }) => {
    // Debounce the input to keep clean RPC calls when resolving ENS names
    // If the input is an address, we don't need to debounce it
    const [_debouncedValue] = (0, usehooks_ts_1.useDebounceValue)(value, 500);
    const debouncedValue = (0, viem_1.isAddress)(value) ? value : _debouncedValue;
    const isDebouncedValueLive = debouncedValue === value;
    // If the user changes the input after an ENS name is already resolved, we want to remove the stale result
    const settledValue = isDebouncedValueLive ? debouncedValue : undefined;
    const { data: ensAddress, isLoading: isEnsAddressLoading, isError: isEnsAddressError, isSuccess: isEnsAddressSuccess, } = (0, wagmi_1.useEnsAddress)({
        name: settledValue,
        chainId: 1,
        query: {
            gcTime: 30000,
            enabled: isDebouncedValueLive && (0, scaffold_eth_1.isENS)(debouncedValue),
        },
    });
    const [enteredEnsName, setEnteredEnsName] = (0, react_1.useState)();
    const { data: ensName, isLoading: isEnsNameLoading, isError: isEnsNameError, isSuccess: isEnsNameSuccess, } = (0, wagmi_1.useEnsName)({
        address: settledValue,
        chainId: 1,
        query: {
            enabled: (0, viem_1.isAddress)(debouncedValue),
            gcTime: 30000,
        },
    });
    const { data: ensAvatar, isLoading: isEnsAvatarLoading } = (0, wagmi_1.useEnsAvatar)({
        name: ensName ? (0, ens_1.normalize)(ensName) : undefined,
        chainId: 1,
        query: {
            enabled: Boolean(ensName),
            gcTime: 30000,
        },
    });
    // ens => address
    (0, react_1.useEffect)(() => {
        if (!ensAddress)
            return;
        // ENS resolved successfully
        setEnteredEnsName(debouncedValue);
        onChange(ensAddress);
    }, [ensAddress, onChange, debouncedValue]);
    const handleChange = (0, react_1.useCallback)((newValue) => {
        setEnteredEnsName(undefined);
        onChange(newValue);
    }, [onChange]);
    const reFocus = isEnsAddressError ||
        isEnsNameError ||
        isEnsNameSuccess ||
        isEnsAddressSuccess ||
        ensName === null ||
        ensAddress === null;
    return (<scaffold_eth_1.InputBase name={name} placeholder={placeholder} error={ensAddress === null} value={value} onChange={handleChange} disabled={isEnsAddressLoading || isEnsNameLoading || disabled} reFocus={reFocus} prefix={ensName ? (<div className="flex bg-base-300 rounded-l-full items-center">
            {isEnsAvatarLoading && <div className="skeleton bg-base-200 w-[35px] h-[35px] rounded-full shrink-0"></div>}
            {ensAvatar ? (<span className="w-[35px]">
                {
                // eslint-disable-next-line
                <img className="w-full rounded-full" src={ensAvatar} alt={`${ensAddress} avatar`}/>}
              </span>) : null}
            <span className="text-accent px-2">{enteredEnsName !== null && enteredEnsName !== void 0 ? enteredEnsName : ensName}</span>
          </div>) : ((isEnsNameLoading || isEnsAddressLoading) && (<div className="flex bg-base-300 rounded-l-full items-center gap-2 pr-2">
              <div className="skeleton bg-base-200 w-[35px] h-[35px] rounded-full shrink-0"></div>
              <div className="skeleton bg-base-200 h-3 w-20"></div>
            </div>))} suffix={
        // Don't want to use nextJS Image here (and adding remote patterns for the URL)
        // eslint-disable-next-line @next/next/no-img-element
        value && <img alt="" className="!rounded-full" src={(0, blo_1.blo)(value)} width="35" height="35"/>}/>);
};
exports.AddressInput = AddressInput;
