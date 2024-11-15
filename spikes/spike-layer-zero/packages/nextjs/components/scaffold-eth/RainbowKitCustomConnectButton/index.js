"use strict";
"use client";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RainbowKitCustomConnectButton = void 0;
// @refresh reset
const Balance_1 = require("../Balance");
const AddressInfoDropdown_1 = require("./AddressInfoDropdown");
const AddressQRCodeModal_1 = require("./AddressQRCodeModal");
const WrongNetworkDropdown_1 = require("./WrongNetworkDropdown");
const rainbowkit_1 = require("@rainbow-me/rainbowkit");
const scaffold_eth_1 = require("~~/hooks/scaffold-eth");
const useTargetNetwork_1 = require("~~/hooks/scaffold-eth/useTargetNetwork");
const scaffold_eth_2 = require("~~/utils/scaffold-eth");
/**
 * Custom Wagmi Connect Button (watch balance + custom design)
 */
const RainbowKitCustomConnectButton = () => {
    const networkColor = (0, scaffold_eth_1.useNetworkColor)();
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    return (<rainbowkit_1.ConnectButton.Custom>
      {({ account, chain, openConnectModal, mounted }) => {
            const connected = mounted && account && chain;
            const blockExplorerAddressLink = account
                ? (0, scaffold_eth_2.getBlockExplorerAddressLink)(targetNetwork, account.address)
                : undefined;
            return (<>
            {(() => {
                    if (!connected) {
                        return (<button className="btn btn-primary btn-sm" onClick={openConnectModal} type="button">
                    Connect Wallet
                  </button>);
                    }
                    if (chain.unsupported || chain.id !== targetNetwork.id) {
                        return <WrongNetworkDropdown_1.WrongNetworkDropdown />;
                    }
                    return (<>
                  <div className="flex flex-col items-center mr-1">
                    <Balance_1.Balance address={account.address} className="min-h-0 h-auto"/>
                    <span className="text-xs" style={{ color: networkColor }}>
                      {chain.name}
                    </span>
                  </div>
                  <AddressInfoDropdown_1.AddressInfoDropdown address={account.address} displayName={account.displayName} ensAvatar={account.ensAvatar} blockExplorerAddressLink={blockExplorerAddressLink}/>
                  <AddressQRCodeModal_1.AddressQRCodeModal address={account.address} modalId="qrcode-modal"/>
                </>);
                })()}
          </>);
        }}
    </rainbowkit_1.ConnectButton.Custom>);
};
exports.RainbowKitCustomConnectButton = RainbowKitCustomConnectButton;
