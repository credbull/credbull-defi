"use strict";
"use client";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Faucet = void 0;
const react_1 = require("react");
const viem_1 = require("viem");
const chains_1 = require("viem/chains");
const wagmi_1 = require("wagmi");
const outline_1 = require("@heroicons/react/24/outline");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const scaffold_eth_2 = require("~~/hooks/scaffold-eth");
const scaffold_eth_3 = require("~~/utils/scaffold-eth");
// Account index to use from generated hardhat accounts.
const FAUCET_ACCOUNT_INDEX = 0;
const localWalletClient = (0, viem_1.createWalletClient)({
    chain: chains_1.hardhat,
    transport: (0, viem_1.http)(),
});
/**
 * Faucet modal which lets you send ETH to any address.
 */
const Faucet = () => {
    const [loading, setLoading] = (0, react_1.useState)(false);
    const [inputAddress, setInputAddress] = (0, react_1.useState)();
    const [faucetAddress, setFaucetAddress] = (0, react_1.useState)();
    const [sendValue, setSendValue] = (0, react_1.useState)("");
    const { chain: ConnectedChain } = (0, wagmi_1.useAccount)();
    const faucetTxn = (0, scaffold_eth_2.useTransactor)(localWalletClient);
    (0, react_1.useEffect)(() => {
        const getFaucetAddress = () => __awaiter(void 0, void 0, void 0, function* () {
            try {
                const accounts = yield localWalletClient.getAddresses();
                setFaucetAddress(accounts[FAUCET_ACCOUNT_INDEX]);
            }
            catch (error) {
                scaffold_eth_3.notification.error(<>
            <p className="font-bold mt-0 mb-1">Cannot connect to local provider</p>
            <p className="m-0">
              - Did you forget to run <code className="italic bg-base-300 text-base font-bold">yarn chain</code> ?
            </p>
            <p className="mt-1 break-normal">
              - Or you can change <code className="italic bg-base-300 text-base font-bold">targetNetwork</code> in{" "}
              <code className="italic bg-base-300 text-base font-bold">scaffold.config.ts</code>
            </p>
          </>);
                console.error("⚡️ ~ file: Faucet.tsx:getFaucetAddress ~ error", error);
            }
        });
        getFaucetAddress();
    }, []);
    const sendETH = () => __awaiter(void 0, void 0, void 0, function* () {
        if (!faucetAddress || !inputAddress) {
            return;
        }
        try {
            setLoading(true);
            yield faucetTxn({
                to: inputAddress,
                value: (0, viem_1.parseEther)(sendValue),
                account: faucetAddress,
            });
            setLoading(false);
            setInputAddress(undefined);
            setSendValue("");
        }
        catch (error) {
            console.error("⚡️ ~ file: Faucet.tsx:sendETH ~ error", error);
            setLoading(false);
        }
    });
    // Render only on local chain
    if ((ConnectedChain === null || ConnectedChain === void 0 ? void 0 : ConnectedChain.id) !== chains_1.hardhat.id) {
        return null;
    }
    return (<div>
      <label htmlFor="faucet-modal" className="btn btn-primary btn-sm font-normal gap-1">
        <outline_1.BanknotesIcon className="h-4 w-4"/>
        <span>Faucet</span>
      </label>
      <input type="checkbox" id="faucet-modal" className="modal-toggle"/>
      <label htmlFor="faucet-modal" className="modal cursor-pointer">
        <label className="modal-box relative">
          {/* dummy input to capture event onclick on modal box */}
          <input className="h-0 w-0 absolute top-0 left-0"/>
          <h3 className="text-xl font-bold mb-3">Local Faucet</h3>
          <label htmlFor="faucet-modal" className="btn btn-ghost btn-sm btn-circle absolute right-3 top-3">
            ✕
          </label>
          <div className="space-y-3">
            <div className="flex space-x-4">
              <div>
                <span className="text-sm font-bold">From:</span>
                <scaffold_eth_1.Address address={faucetAddress}/>
              </div>
              <div>
                <span className="text-sm font-bold pl-3">Available:</span>
                <scaffold_eth_1.Balance address={faucetAddress}/>
              </div>
            </div>
            <div className="flex flex-col space-y-3">
              <scaffold_eth_1.AddressInput placeholder="Destination Address" value={inputAddress !== null && inputAddress !== void 0 ? inputAddress : ""} onChange={value => setInputAddress(value)}/>
              <scaffold_eth_1.EtherInput placeholder="Amount to send" value={sendValue} onChange={value => setSendValue(value)}/>
              <button className="h-10 btn btn-primary btn-sm px-2 rounded-full" onClick={sendETH} disabled={loading}>
                {!loading ? (<outline_1.BanknotesIcon className="h-6 w-6"/>) : (<span className="loading loading-spinner loading-sm"></span>)}
                <span>Send</span>
              </button>
            </div>
          </div>
        </label>
      </label>
    </div>);
};
exports.Faucet = Faucet;
