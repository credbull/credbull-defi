"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Footer = void 0;
const react_1 = __importDefault(require("react"));
const link_1 = __importDefault(require("next/link"));
const chains_1 = require("viem/chains");
const outline_1 = require("@heroicons/react/24/outline");
const outline_2 = require("@heroicons/react/24/outline");
const SwitchTheme_1 = require("~~/components/SwitchTheme");
const BuidlGuidlLogo_1 = require("~~/components/assets/BuidlGuidlLogo");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const useTargetNetwork_1 = require("~~/hooks/scaffold-eth/useTargetNetwork");
const store_1 = require("~~/services/store/store");
/**
 * Site footer
 */
const Footer = () => {
    const nativeCurrencyPrice = (0, store_1.useGlobalState)(state => state.nativeCurrency.price);
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const isLocalNetwork = targetNetwork.id === chains_1.hardhat.id;
    return (<div className="min-h-0 py-5 px-1 mb-11 lg:mb-0">
      <div>
        <div className="fixed flex justify-between items-center w-full z-10 p-4 bottom-0 left-0 pointer-events-none">
          <div className="flex flex-col md:flex-row gap-2 pointer-events-auto">
            {nativeCurrencyPrice > 0 && (<div>
                <div className="btn btn-primary btn-sm font-normal gap-1 cursor-auto">
                  <outline_1.CurrencyDollarIcon className="h-4 w-4"/>
                  <span>{nativeCurrencyPrice.toFixed(2)}</span>
                </div>
              </div>)}
            {isLocalNetwork && (<>
                <scaffold_eth_1.Faucet />
                <link_1.default href="/blockexplorer" passHref className="btn btn-primary btn-sm font-normal gap-1">
                  <outline_1.MagnifyingGlassIcon className="h-4 w-4"/>
                  <span>Block Explorer</span>
                </link_1.default>
              </>)}
          </div>
          <SwitchTheme_1.SwitchTheme className={`pointer-events-auto ${isLocalNetwork ? "self-end md:self-auto" : ""}`}/>
        </div>
      </div>
      <div className="w-full">
        <ul className="menu menu-horizontal w-full">
          <div className="flex justify-center items-center gap-2 text-sm w-full">
            <div className="text-center">
              <a href="https://github.com/scaffold-eth/se-2" target="_blank" rel="noreferrer" className="link">
                Fork me
              </a>
            </div>
            <span>·</span>
            <div className="flex justify-center items-center gap-2">
              <p className="m-0 text-center">
                Built with <outline_2.HeartIcon className="inline-block h-4 w-4"/> at
              </p>
              <a className="flex justify-center items-center gap-1" href="https://buidlguidl.com/" target="_blank" rel="noreferrer">
                <BuidlGuidlLogo_1.BuidlGuidlLogo className="w-3 h-5 pb-1"/>
                <span className="link">BuidlGuidl</span>
              </a>
            </div>
            <span>·</span>
            <div className="text-center">
              <a href="https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA" target="_blank" rel="noreferrer" className="link">
                Support
              </a>
            </div>
          </div>
        </ul>
      </div>
    </div>);
};
exports.Footer = Footer;
