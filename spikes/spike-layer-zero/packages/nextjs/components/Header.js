"use strict";
"use client";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Header = exports.HeaderMenuLinks = exports.menuLinks = void 0;
const react_1 = __importStar(require("react"));
const image_1 = __importDefault(require("next/image"));
const link_1 = __importDefault(require("next/link"));
const navigation_1 = require("next/navigation");
const outline_1 = require("@heroicons/react/24/outline");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const scaffold_eth_2 = require("~~/hooks/scaffold-eth");
exports.menuLinks = [
    {
        label: "Home",
        href: "/",
    },
    {
        label: "Debug Contracts",
        href: "/debug",
        icon: <outline_1.BugAntIcon className="h-4 w-4"/>,
    },
];
const HeaderMenuLinks = () => {
    const pathname = (0, navigation_1.usePathname)();
    return (<>
      {exports.menuLinks.map(({ label, href, icon }) => {
            const isActive = pathname === href;
            return (<li key={href}>
            <link_1.default href={href} passHref className={`${isActive ? "bg-secondary shadow-md" : ""} hover:bg-secondary hover:shadow-md focus:!bg-secondary active:!text-neutral py-1.5 px-3 text-sm rounded-full gap-2 grid grid-flow-col`}>
              {icon}
              <span>{label}</span>
            </link_1.default>
          </li>);
        })}
    </>);
};
exports.HeaderMenuLinks = HeaderMenuLinks;
/**
 * Site header
 */
const Header = () => {
    const [isDrawerOpen, setIsDrawerOpen] = (0, react_1.useState)(false);
    const burgerMenuRef = (0, react_1.useRef)(null);
    (0, scaffold_eth_2.useOutsideClick)(burgerMenuRef, (0, react_1.useCallback)(() => setIsDrawerOpen(false), []));
    return (<div className="sticky lg:static top-0 navbar bg-base-100 min-h-0 flex-shrink-0 justify-between z-20 shadow-md shadow-secondary px-0 sm:px-2">
      <div className="navbar-start w-auto lg:w-1/2">
        <div className="lg:hidden dropdown" ref={burgerMenuRef}>
          <label tabIndex={0} className={`ml-1 btn btn-ghost ${isDrawerOpen ? "hover:bg-secondary" : "hover:bg-transparent"}`} onClick={() => {
            setIsDrawerOpen(prevIsOpenState => !prevIsOpenState);
        }}>
            <outline_1.Bars3Icon className="h-1/2"/>
          </label>
          {isDrawerOpen && (<ul tabIndex={0} className="menu menu-compact dropdown-content mt-3 p-2 shadow bg-base-100 rounded-box w-52" onClick={() => {
                setIsDrawerOpen(false);
            }}>
              <exports.HeaderMenuLinks />
            </ul>)}
        </div>
        <link_1.default href="/" passHref className="hidden lg:flex items-center gap-2 ml-4 mr-6 shrink-0">
          <div className="flex relative w-10 h-10">
            <image_1.default alt="SE2 logo" className="cursor-pointer" fill src="/logo.svg"/>
          </div>
          <div className="flex flex-col">
            <span className="font-bold leading-tight">Scaffold-ETH</span>
            <span className="text-xs">Ethereum dev stack</span>
          </div>
        </link_1.default>
        <ul className="hidden lg:flex lg:flex-nowrap menu menu-horizontal px-1 gap-2">
          <exports.HeaderMenuLinks />
        </ul>
      </div>
      <div className="navbar-end flex-grow mr-4">
        <scaffold_eth_1.RainbowKitCustomConnectButton />
        <scaffold_eth_1.FaucetButton />
      </div>
    </div>);
};
exports.Header = Header;
