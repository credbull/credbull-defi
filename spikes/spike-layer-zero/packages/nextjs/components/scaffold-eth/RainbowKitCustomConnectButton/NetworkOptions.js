"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NetworkOptions = void 0;
const next_themes_1 = require("next-themes");
const wagmi_1 = require("wagmi");
const solid_1 = require("@heroicons/react/24/solid");
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
const scaffold_eth_2 = require("~~/utils/scaffold-eth");
const allowedNetworks = (0, scaffold_eth_2.getTargetNetworks)();
const NetworkOptions = ({ hidden = false }) => {
    const { switchChain } = (0, wagmi_1.useSwitchChain)();
    const { chain } = (0, wagmi_1.useAccount)();
    const { resolvedTheme } = (0, next_themes_1.useTheme)();
    const isDarkMode = resolvedTheme === "dark";
    return (<>
      {allowedNetworks
            .filter(allowedNetwork => allowedNetwork.id !== (chain === null || chain === void 0 ? void 0 : chain.id))
            .map(allowedNetwork => (<li key={allowedNetwork.id} className={hidden ? "hidden" : ""}>
            <button className="menu-item btn-sm !rounded-xl flex gap-3 py-3 whitespace-nowrap" type="button" onClick={() => {
                switchChain === null || switchChain === void 0 ? void 0 : switchChain({ chainId: allowedNetwork.id });
            }}>
              <solid_1.ArrowsRightLeftIcon className="h-6 w-4 ml-2 sm:ml-0"/>
              <span>
                Switch to{" "}
                <span style={{
                color: (0, scaffold_eth_1.getNetworkColor)(allowedNetwork, isDarkMode),
            }}>
                  {allowedNetwork.name}
                </span>
              </span>
            </button>
          </li>))}
    </>);
};
exports.NetworkOptions = NetworkOptions;
