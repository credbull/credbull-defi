"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WrongNetworkDropdown = void 0;
const NetworkOptions_1 = require("./NetworkOptions");
const wagmi_1 = require("wagmi");
const outline_1 = require("@heroicons/react/24/outline");
const WrongNetworkDropdown = () => {
    const { disconnect } = (0, wagmi_1.useDisconnect)();
    return (<div className="dropdown dropdown-end mr-2">
      <label tabIndex={0} className="btn btn-error btn-sm dropdown-toggle gap-1">
        <span>Wrong network</span>
        <outline_1.ChevronDownIcon className="h-6 w-4 ml-2 sm:ml-0"/>
      </label>
      <ul tabIndex={0} className="dropdown-content menu p-2 mt-1 shadow-center shadow-accent bg-base-200 rounded-box gap-1">
        <NetworkOptions_1.NetworkOptions />
        <li>
          <button className="menu-item text-error btn-sm !rounded-xl flex gap-3 py-3" type="button" onClick={() => disconnect()}>
            <outline_1.ArrowLeftOnRectangleIcon className="h-6 w-4 ml-2 sm:ml-0"/>
            <span>Disconnect</span>
          </button>
        </li>
      </ul>
    </div>);
};
exports.WrongNetworkDropdown = WrongNetworkDropdown;
