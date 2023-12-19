"use client";
import { Web3Auth } from "@web3auth/modal";
import {
  CHAIN_NAMESPACES,
  IProvider,
  SafeEventEmitterProvider,
} from "@web3auth/base";
import RPC from "./utils/web3RPC";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import Button from "@/components/button";
import UiConsole from "@/components/UiConsole";
import {
  authenticateUser,
  getAccounts,
  getBalance,
  getChainId,
  getUserInfo,
  login,
  logout,
} from "./utils/macros";

// Get your Client ID from the Web3Auth Dashboard

const clientId =
  "BPrSUOrtJaYE2KRNB5TJNFhcOod6w8HIAtm0tdRtyppCIkLxuE5eKBIkwiWZNz_SMPzNg9KHKyPzAZQOzTICxxs";

export default function Home() {
  const [web3auth, setWeb3auth] = useState<Web3Auth | null>(null);
  const [provider, setProvider] = useState<IProvider | null>(null);
  const [flag, setFlag] = useState<boolean>(false);

  useEffect(() => {
    const init = async () => {
      try {
        const web3auth = new Web3Auth({
          clientId,
          web3AuthNetwork: "sapphire_mainnet", // mainnet, aqua,  cyan or testnet
          // chainConfig: {
          //   chainNamespace: CHAIN_NAMESPACES.EIP155,
          //   chainId: "0x1",
          //   rpcTarget: "https://rpc.ankr.com/eth", // This is the public RPC we have added, please pass on your own endpoint while creating an app
          // },
          chainConfig: {
            //   chainId: "31337",
            //   rpcTarget: "http://127.0.0.1:8545",
            //   chainNamespace: "other",
            //   displayName: "Foundry",

            chainNamespace: "eip155",
            chainId: "0x5",
            rpcTarget:
              "https://goerli.infura.io/v3/d437a2fff7994b6f9f936e1251890dc4",
            displayName: "Ethereum Mainnet",
            blockExplorer: "https://etherscan.io",
            ticker: "GoerliETH",
            tickerName: "Goerli Ethereum",

            // chainNamespace: "eip155",
            // chainId: "0x1",
            // rpcTarget: "https://eth-mainnet.g.alchemy.com/v2/Qz3bxTSDHeaelUhUPOUD6WZFsHGqVx3Z",
            // displayName: "Ethereum Mainnet",
            // blockExplorer: "https://etherscan.io",
            // ticker: "ETH",
            // tickerName: "Ethereum",
          },
        });

        setWeb3auth(web3auth);

        await web3auth.initModal();

        if (web3auth.provider) {
          console.log(web3auth);
          setProvider(web3auth.provider);
        }
      } catch (error) {
        console.error(error);
      }
    };

    init();
  }, []);

  const loggedInView = (
    <>
      <div className="flex-container">
        <div>
          <Button
            onClick={() => getUserInfo(web3auth)}
            buttonText="Get UserInfo"
          />
        </div>
        <div>
          <Button
            onClick={() => authenticateUser(web3auth)}
            buttonText="Get ID Token"
          />
        </div>
        <div>
          <Button
            onClick={() => getChainId(provider)}
            buttonText="Get Chain ID"
          />
        </div>
        <div>
          <Button
            onClick={() => getAccounts(provider)}
            buttonText="Get Accounts"
          />
        </div>
        <div>
          <Button
            onClick={() => getBalance(provider)}
            buttonText="Get Balance"
          />
        </div>

        <div>
          <Button
            onClick={() => logout(web3auth, setProvider, setFlag, flag)}
            buttonText="Log Out"
          />
        </div>
      </div>

      <div id="console" style={{ whiteSpace: "pre-line" }}>
        <p style={{ whiteSpace: "pre-line", maxWidth: 400 }}>
          Logged in Successfully!
        </p>
      </div>
    </>
  );

  const unloggedInView = (
    <Button
      buttonText="Login"
      onClick={() => login(web3auth, setProvider, setFlag, flag)}
    ></Button>
  );

  return (
    <main
      className="flex min-h-screen flex-col items-center justify-between p-24"
      style={{ backgroundColor: "#111928" }}
    >
      <header className="App-header">
        {flag ? loggedInView : unloggedInView}
      </header>
    </main>
  );
}
