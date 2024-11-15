"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddressInfoDropdown = void 0;
const react_1 = require("react");
const NetworkOptions_1 = require("./NetworkOptions");
const react_copy_to_clipboard_1 = __importDefault(require("react-copy-to-clipboard"));
const viem_1 = require("viem");
const wagmi_1 = require("wagmi");
const outline_1 = require("@heroicons/react/24/outline");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const scaffold_eth_2 = require("~~/hooks/scaffold-eth");
const scaffold_eth_3 = require("~~/utils/scaffold-eth");
const allowedNetworks = (0, scaffold_eth_3.getTargetNetworks)();
const AddressInfoDropdown = ({ address, ensAvatar, displayName, blockExplorerAddressLink, }) => {
    const { disconnect } = (0, wagmi_1.useDisconnect)();
    const checkSumAddress = (0, viem_1.getAddress)(address);
    const [addressCopied, setAddressCopied] = (0, react_1.useState)(false);
    const [selectingNetwork, setSelectingNetwork] = (0, react_1.useState)(false);
    const dropdownRef = (0, react_1.useRef)(null);
    const closeDropdown = () => {
        var _a;
        setSelectingNetwork(false);
        (_a = dropdownRef.current) === null || _a === void 0 ? void 0 : _a.removeAttribute("open");
    };
    (0, scaffold_eth_2.useOutsideClick)(dropdownRef, closeDropdown);
    return (<>
      <details ref={dropdownRef} className="dropdown dropdown-end leading-3">
        <summary tabIndex={0} className="btn btn-secondary btn-sm pl-0 pr-2 shadow-md dropdown-toggle gap-0 !h-auto">
          <scaffold_eth_1.BlockieAvatar address={checkSumAddress} size={30} ensImage={ensAvatar}/>
          <span className="ml-2 mr-1">
            {(0, scaffold_eth_1.isENS)(displayName) ? displayName : (checkSumAddress === null || checkSumAddress === void 0 ? void 0 : checkSumAddress.slice(0, 6)) + "..." + (checkSumAddress === null || checkSumAddress === void 0 ? void 0 : checkSumAddress.slice(-4))}
          </span>
          <outline_1.ChevronDownIcon className="h-6 w-4 ml-2 sm:ml-0"/>
        </summary>
        <ul tabIndex={0} className="dropdown-content menu z-[2] p-2 mt-2 shadow-center shadow-accent bg-base-200 rounded-box gap-1">
          <NetworkOptions_1.NetworkOptions hidden={!selectingNetwork}/>
          <li className={selectingNetwork ? "hidden" : ""}>
            {addressCopied ? (<div className="btn-sm !rounded-xl flex gap-3 py-3">
                <outline_1.CheckCircleIcon className="text-xl font-normal h-6 w-4 cursor-pointer ml-2 sm:ml-0" aria-hidden="true"/>
                <span className=" whitespace-nowrap">Copy address</span>
              </div>) : (<react_copy_to_clipboard_1.default text={checkSumAddress} onCopy={() => {
                setAddressCopied(true);
                setTimeout(() => {
                    setAddressCopied(false);
                }, 800);
            }}>
                <div className="btn-sm !rounded-xl flex gap-3 py-3">
                  <outline_1.DocumentDuplicateIcon className="text-xl font-normal h-6 w-4 cursor-pointer ml-2 sm:ml-0" aria-hidden="true"/>
                  <span className=" whitespace-nowrap">Copy address</span>
                </div>
              </react_copy_to_clipboard_1.default>)}
          </li>
          <li className={selectingNetwork ? "hidden" : ""}>
            <label htmlFor="qrcode-modal" className="btn-sm !rounded-xl flex gap-3 py-3">
              <outline_1.QrCodeIcon className="h-6 w-4 ml-2 sm:ml-0"/>
              <span className="whitespace-nowrap">View QR Code</span>
            </label>
          </li>
          <li className={selectingNetwork ? "hidden" : ""}>
            <button className="menu-item btn-sm !rounded-xl flex gap-3 py-3" type="button">
              <outline_1.ArrowTopRightOnSquareIcon className="h-6 w-4 ml-2 sm:ml-0"/>
              <a target="_blank" href={blockExplorerAddressLink} rel="noopener noreferrer" className="whitespace-nowrap">
                View on Block Explorer
              </a>
            </button>
          </li>
          {allowedNetworks.length > 1 ? (<li className={selectingNetwork ? "hidden" : ""}>
              <button className="btn-sm !rounded-xl flex gap-3 py-3" type="button" onClick={() => {
                setSelectingNetwork(true);
            }}>
                <outline_1.ArrowsRightLeftIcon className="h-6 w-4 ml-2 sm:ml-0"/> <span>Switch Network</span>
              </button>
            </li>) : null}
          <li className={selectingNetwork ? "hidden" : ""}>
            <button className="menu-item text-error btn-sm !rounded-xl flex gap-3 py-3" type="button" onClick={() => disconnect()}>
              <outline_1.ArrowLeftOnRectangleIcon className="h-6 w-4 ml-2 sm:ml-0"/> <span>Disconnect</span>
            </button>
          </li>
        </ul>
      </details>
    </>);
};
exports.AddressInfoDropdown = AddressInfoDropdown;
