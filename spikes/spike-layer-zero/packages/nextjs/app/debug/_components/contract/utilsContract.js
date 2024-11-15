"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.transformAbiFunction = exports.getInitialTupleArrayFormState = exports.getInitialTupleFormState = exports.getParsedContractFunctionArgs = exports.getInitialFormState = exports.getFunctionInputKey = void 0;
/**
 * Generates a key based on function metadata
 */
const getFunctionInputKey = (functionName, input, inputIndex) => {
    const name = (input === null || input === void 0 ? void 0 : input.name) || `input_${inputIndex}_`;
    return functionName + "_" + name + "_" + input.internalType + "_" + input.type;
};
exports.getFunctionInputKey = getFunctionInputKey;
const isJsonString = (str) => {
    try {
        JSON.parse(str);
        return true;
    }
    catch (e) {
        return false;
    }
};
const isBigInt = (str) => {
    if (str.trim().length === 0 || str.startsWith("0"))
        return false;
    try {
        BigInt(str);
        return true;
    }
    catch (e) {
        return false;
    }
};
// Recursive function to deeply parse JSON strings, correctly handling nested arrays and encoded JSON strings
const deepParseValues = (value) => {
    if (typeof value === "string") {
        // first try with bigInt because we losse precision with JSON.parse
        if (isBigInt(value)) {
            return BigInt(value);
        }
        if (isJsonString(value)) {
            const parsed = JSON.parse(value);
            return deepParseValues(parsed);
        }
        // It's a string but not a JSON string, return as is
        return value;
    }
    else if (Array.isArray(value)) {
        // If it's an array, recursively parse each element
        return value.map(element => deepParseValues(element));
    }
    else if (typeof value === "object" && value !== null) {
        // If it's an object, recursively parse each value
        return Object.entries(value).reduce((acc, [key, val]) => {
            acc[key] = deepParseValues(val);
            return acc;
        }, {});
    }
    // Handle boolean values represented as strings
    if (value === "true" || value === "1" || value === "0x1" || value === "0x01" || value === "0x0001") {
        return true;
    }
    else if (value === "false" || value === "0" || value === "0x0" || value === "0x00" || value === "0x0000") {
        return false;
    }
    return value;
};
/**
 * parses form input with array support
 */
const getParsedContractFunctionArgs = (form) => {
    return Object.keys(form).map(key => {
        const valueOfArg = form[key];
        // Attempt to deeply parse JSON strings
        return deepParseValues(valueOfArg);
    });
};
exports.getParsedContractFunctionArgs = getParsedContractFunctionArgs;
const getInitialFormState = (abiFunction) => {
    const initialForm = {};
    if (!abiFunction.inputs)
        return initialForm;
    abiFunction.inputs.forEach((input, inputIndex) => {
        const key = getFunctionInputKey(abiFunction.name, input, inputIndex);
        initialForm[key] = "";
    });
    return initialForm;
};
exports.getInitialFormState = getInitialFormState;
const getInitialTupleFormState = (abiTupleParameter) => {
    const initialForm = {};
    if (abiTupleParameter.components.length === 0)
        return initialForm;
    abiTupleParameter.components.forEach((component, componentIndex) => {
        const key = getFunctionInputKey(abiTupleParameter.name || "tuple", component, componentIndex);
        initialForm[key] = "";
    });
    return initialForm;
};
exports.getInitialTupleFormState = getInitialTupleFormState;
const getInitialTupleArrayFormState = (abiTupleParameter) => {
    const initialForm = {};
    if (abiTupleParameter.components.length === 0)
        return initialForm;
    abiTupleParameter.components.forEach((component, componentIndex) => {
        const key = getFunctionInputKey("0_" + abiTupleParameter.name || "tuple", component, componentIndex);
        initialForm[key] = "";
    });
    return initialForm;
};
exports.getInitialTupleArrayFormState = getInitialTupleArrayFormState;
const adjustInput = (input) => {
    if (input.type.startsWith("tuple[")) {
        const depth = (input.type.match(/\[\]/g) || []).length;
        return Object.assign(Object.assign({}, input), { components: transformComponents(input.components, depth, {
                internalType: input.internalType || "struct",
                name: input.name,
            }) });
    }
    else if (input.components) {
        return Object.assign(Object.assign({}, input), { components: input.components.map(value => adjustInput(value)) });
    }
    return input;
};
const transformComponents = (components, depth, parentComponentData) => {
    // Base case: if depth is 1 or no components, return the original components
    if (depth === 1 || !components) {
        return [...components];
    }
    // Recursive case: wrap components in an additional tuple layer
    const wrappedComponents = {
        internalType: `${parentComponentData.internalType || "struct"}`.replace(/\[\]/g, "") + "[]".repeat(depth - 1),
        name: `${parentComponentData.name || "tuple"}`,
        type: `tuple${"[]".repeat(depth - 1)}`,
        components: transformComponents(components, depth - 1, parentComponentData),
    };
    return [wrappedComponents];
};
const transformAbiFunction = (abiFunction) => {
    return Object.assign(Object.assign({}, abiFunction), { inputs: abiFunction.inputs.map(value => adjustInput(value)) });
};
exports.transformAbiFunction = transformAbiFunction;
