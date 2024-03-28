import {
  CredbullFixedYieldVaultWithUpside__factory,
  CredbullFixedYieldVault__factory,
  ERC20__factory,
} from '@credbull/contracts';
import { BigNumber, Signer } from 'ethers';
import { ethers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';

import { decodeContractError } from './src/utils/utils';

export class CredbullSDK {
  private SERVICE_URL = 'http://localhost:3001';
  constructor(
    private access_token: string,
    private signer: Signer,
  ) {}

  private headers() {
    return {
      headers: {
        'Content-Type': 'application/json',
        ...(this.access_token ? { Authorization: `Bearer ${this.access_token}` } : {}),
      },
    };
  }

  private async linkWalletMessage(signer: Signer) {
    const chainId = await signer.getChainId();
    const preMessage = new SiweMessage({
      domain: this.SERVICE_URL.split('//')[1],
      address: await signer.getAddress(),
      statement: 'By connecting your wallet, you agree to the Terms of Service and Privacy Policy.',
      uri: 'http://localhost:3001',
      version: '1',
      chainId,
      nonce: generateNonce(),
    });

    return preMessage.prepareMessage();
  }

  private handleError(contract: ethers.Contract, error: any) {
    if (error.error?.data?.data) {
      decodeContractError(contract, error.error.data.data);
    } else if (error.error?.error?.error?.data) {
      decodeContractError(contract, error.error.error.error.data);
    } else {
      console.log(error);
      throw error;
    }
  }

  /// Return all active vaults
  async getAllVaults() {
    const vaultsData = await fetch(`${this.SERVICE_URL}/vaults/current`, { method: 'GET', ...this.headers() });
    return await vaultsData.json();
  }

  /// Link user wallet
  async linkWallet(discriminator?: string) {
    console.log('in link wallet');
    const message = await this.linkWalletMessage(this.signer);
    const signature = await this.signer.signMessage(message);

    const linkWallet = await fetch(`${this.SERVICE_URL}/accounts/link-wallet`, {
      method: 'POST',
      body: JSON.stringify({ message, signature, discriminator }),
      ...this.headers(),
    });

    return await linkWallet.json();
  }

  /// Deposit token to the given vault address
  async deposit(vaultAddress: string, amount: BigNumber, receiver: string) {
    const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    await vault.deposit(amount, receiver).catch((err) => this.handleError(vault, err));
  }

  /// Redeem the share tokens
  async redeem(vaultAddress: string, shares: BigNumber, receiver: string) {
    const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    await vault.redeem(shares, receiver, receiver).catch((err) => this.handleError(vault, err));
  }

  /// Get the instance of an asset associated with the vault
  async getAssetInstance(vaultAddress: string) {
    const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    const assetAddress = await vault.asset().catch((err) => this.handleError(vault, err));
    return ERC20__factory.connect(assetAddress as string, this.signer);
  }

  /// Get the instance of the vault
  async getVaultInstance(vaultAddress: string) {
    return CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
  }

  /// Get upside vault instance
  async getUpsideVaultInstance(vaultAddress: string) {
    return CredbullFixedYieldVaultWithUpside__factory.connect(vaultAddress, this.signer);
  }

  async getTokenInstance(vaultAddress: string) {
    const vault = CredbullFixedYieldVaultWithUpside__factory.connect(vaultAddress, this.signer);
    const tokenAddress = await vault.token().catch((err) => this.handleError(vault, err));
    return ERC20__factory.connect(tokenAddress as string, this.signer);
  }
}
