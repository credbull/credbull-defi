import UiConsole from "@/components/UiConsole";
import { IProvider } from "@web3auth/base";
import { Web3Auth } from "@web3auth/modal";
import { Dispatch, SetStateAction } from "react";
import RPC from "./web3RPC";

export const login = async (
  web3auth: Web3Auth | null,
  setProvider: Dispatch<SetStateAction<IProvider | null>>,
  setFlag: Dispatch<SetStateAction<boolean>>,
  flag: boolean
) => {
  if (!web3auth) {
    UiConsole("web3auth not initialized yet");
    return;
  }
  const web3authProvider = await web3auth.connect();
  setProvider(web3authProvider);
  setFlag(!flag);
};

export const authenticateUser = async (web3auth: Web3Auth | null) => {
  if (!web3auth) {
    UiConsole("web3auth not initialized yet");
    return;
  }
  const idToken = await web3auth.authenticateUser();
  UiConsole(idToken);
};

export const getUserInfo = async (web3auth: Web3Auth | null) => {
  if (!web3auth) {
    UiConsole("web3auth not initialized yet");
    return;
  }
  const user = await web3auth.getUserInfo();
  UiConsole(user);
};

export const logout = async (
  web3auth: Web3Auth | null,
  setProvider: Dispatch<SetStateAction<IProvider | null>>,
  setFlag: Dispatch<SetStateAction<boolean>>,
  flag: boolean
) => {
  if (!web3auth) {
    UiConsole("web3auth not initialized yet");
    return;
  }
  await web3auth.logout();
  setProvider(null);
  setFlag(!flag);
};

export const getChainId = async (provider: IProvider | null) => {
  if (!provider) {
    UiConsole("provider not initialized yet");
    return;
  }
  const rpc = new RPC(provider);
  const chainId = await rpc.getChainId();
  UiConsole(chainId);
};

export const getAccounts = async (provider: IProvider | null) => {
  if (!provider) {
    UiConsole("provider not initialized yet");
    return;
  }
  const rpc = new RPC(provider);
  const address = await rpc.getAccounts();
  UiConsole(address);
};

export const getBalance = async (provider: IProvider | null) => {
  if (!provider) {
    UiConsole("provider not initialized yet");
    return;
  }
  const rpc = new RPC(provider);
  const balance = await rpc.getBalance();
  UiConsole(balance);
};
