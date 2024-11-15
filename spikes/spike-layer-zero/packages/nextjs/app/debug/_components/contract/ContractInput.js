"use strict";
"use client";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ContractInput = void 0;
const Tuple_1 = require("./Tuple");
const TupleArray_1 = require("./TupleArray");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
/**
 * Generic Input component to handle input's based on their function param type
 */
const ContractInput = ({ setForm, form, stateObjectKey, paramType }) => {
    const inputProps = {
        name: stateObjectKey,
        value: form === null || form === void 0 ? void 0 : form[stateObjectKey],
        placeholder: paramType.name ? `${paramType.type} ${paramType.name}` : paramType.type,
        onChange: (value) => {
            setForm(form => (Object.assign(Object.assign({}, form), { [stateObjectKey]: value })));
        },
    };
    const renderInput = () => {
        switch (paramType.type) {
            case "address":
                return <scaffold_eth_1.AddressInput {...inputProps}/>;
            case "bytes32":
                return <scaffold_eth_1.Bytes32Input {...inputProps}/>;
            case "bytes":
                return <scaffold_eth_1.BytesInput {...inputProps}/>;
            case "string":
                return <scaffold_eth_1.InputBase {...inputProps}/>;
            case "tuple":
                return (<Tuple_1.Tuple setParentForm={setForm} parentForm={form} abiTupleParameter={paramType} parentStateObjectKey={stateObjectKey}/>);
            default:
                // Handling 'int' types and 'tuple[]' types
                if (paramType.type.includes("int") && !paramType.type.includes("[")) {
                    return <scaffold_eth_1.IntegerInput {...inputProps} variant={paramType.type}/>;
                }
                else if (paramType.type.startsWith("tuple[")) {
                    return (<TupleArray_1.TupleArray setParentForm={setForm} parentForm={form} abiTupleParameter={paramType} parentStateObjectKey={stateObjectKey}/>);
                }
                else {
                    return <scaffold_eth_1.InputBase {...inputProps}/>;
                }
        }
    };
    return (<div className="flex flex-col gap-1.5 w-full">
      <div className="flex items-center ml-2">
        {paramType.name && <span className="text-xs font-medium mr-2 leading-none">{paramType.name}</span>}
        <span className="block text-xs font-extralight leading-none">{paramType.type}</span>
      </div>
      {renderInput()}
    </div>);
};
exports.ContractInput = ContractInput;
