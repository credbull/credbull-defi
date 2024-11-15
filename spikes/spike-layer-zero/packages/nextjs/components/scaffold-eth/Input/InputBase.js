"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InputBase = void 0;
const react_1 = require("react");
const InputBase = ({ name, value, onChange, placeholder, error, disabled, prefix, suffix, reFocus, }) => {
    const inputReft = (0, react_1.useRef)(null);
    let modifier = "";
    if (error) {
        modifier = "border-error";
    }
    else if (disabled) {
        modifier = "border-disabled bg-base-300";
    }
    const handleChange = (0, react_1.useCallback)((e) => {
        onChange(e.target.value);
    }, [onChange]);
    // Runs only when reFocus prop is passed, useful for setting the cursor
    // at the end of the input. Example AddressInput
    const onFocus = (e) => {
        if (reFocus !== undefined) {
            e.currentTarget.setSelectionRange(e.currentTarget.value.length, e.currentTarget.value.length);
        }
    };
    (0, react_1.useEffect)(() => {
        var _a;
        if (reFocus !== undefined && reFocus === true)
            (_a = inputReft.current) === null || _a === void 0 ? void 0 : _a.focus();
    }, [reFocus]);
    return (<div className={`flex border-2 border-base-300 bg-base-200 rounded-full text-accent ${modifier}`}>
      {prefix}
      <input className="input input-ghost focus-within:border-transparent focus:outline-none focus:bg-transparent focus:text-gray-400 h-[2.2rem] min-h-[2.2rem] px-4 border w-full font-medium placeholder:text-accent/50 text-gray-400" placeholder={placeholder} name={name} value={value === null || value === void 0 ? void 0 : value.toString()} onChange={handleChange} disabled={disabled} autoComplete="off" ref={inputReft} onFocus={onFocus}/>
      {suffix}
    </div>);
};
exports.InputBase = InputBase;
