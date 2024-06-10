import {
  CredbullFixedYieldVaultWithUpside__factory,
  CredbullFixedYieldVault__factory,
  ERC20__factory,
} from '@credbull/contracts';
import type { CredbullFixedYieldVault, CredbullFixedYieldVaultWithUpside, ERC20 } from '@credbull/contracts';
import { BigNumber, Signer } from 'ethers';
import { ethers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';

import { decodeContractError } from './utils';

// TODO (JL,2024-06-10): The use of the generated Ethers API bypasses the Credbull API.

/**
 * The Credbull SDK for creating and managing Credbull Vaults, via the Credbull API.
 */
export class CredbullSDK {
  // The `URL` for the Credbull API.
  private serviceUrl: URL;

  // Client credentials. Either a Email/Password to login with, or a valid Access Token.
  private login: { email: string, password: String } | null = null;
  private accessToken: string | null = null;

  /**
   * Creates a `CredbullSDK` instance pointed at the `serviceUrl` API backend.
   *
   * @param serviceUrl The `string` API URL. Must be a valid URL.
   * @param credentials The client's credentials. Either an email/password pair or an Access Token.
   * @param signer The `Signer`.
   * @throws TypeError if `serviceUrl` is not a valid URL.
   */
  constructor(
    serviceUrl: string,
    credentials: { email: string, password: string } | { accessToken: string },
    private signer: Signer,
  ) {
    this.serviceUrl = new URL(serviceUrl);
    if ('email' in credentials) {
      this.login = credentials;
    } else {
      this.accessToken = credentials.accessToken;
    }
  }

  private async headers() {
    if (!this.accessToken) {
      await this.connect();
    }
    return {
      headers: {
        'Content-Type': 'application/json',
        ...{ Authorization: `Bearer ${this.accessToken}` },
      },
    };
  }

  private toServiceUrl(path: string): URL {
    return new URL(path, this.serviceUrl);
  }

  private async linkWalletMessage(signer: Signer): Promise<string> {
    const chainId = await signer.getChainId();
    const preMessage = new SiweMessage({
      domain: this.serviceUrl.host,
      address: await signer.getAddress(),
      statement: 'By connecting your wallet, you agree to the Terms of Service and Privacy Policy.',
      uri: this.serviceUrl.href,
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

  /// Connects to the API by logging the configured User in, caching their Access Token for future operations.
  async connect(): Promise<void> {
    return await fetch(this.toServiceUrl('/auth/api/sign-in'), {
      method: 'POST',
      body: JSON.stringify(this.login),
      headers: { 'Content-Type': 'application/json' },
    })
      .then((response) => {
        if (!response.ok) throw new Error(response.statusText);
        return response.json() as Promise<{ access_token: string }>;
      })
      .then((data) => {
        this.accessToken = data.access_token;
      });
  }

  /// Return all active vaults
  async getAllVaults(): Promise<any> {
    const headers = await this.headers();
    const vaultsData = await fetch(this.toServiceUrl('/vaults/current'), { method: 'GET', ...headers });
    return await vaultsData.json();
  }

  /// Link user wallet
  async linkWallet(discriminator?: string): Promise<any> {
    const message = await this.linkWalletMessage(this.signer);
    const signature = await this.signer.signMessage(message);
    const headers = await this.headers();
    const linkWallet = await fetch(this.toServiceUrl('/accounts/link-wallet'), {
      method: 'POST',
      body: JSON.stringify({ message, signature, discriminator }),
      ...headers,
    });

    return await linkWallet.json();
  }

  /// Deposit token to the given vault address
  async deposit(vaultAddress: string, amount: BigNumber, receiver: string): Promise<void> {
    const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    await vault.deposit(amount, receiver).catch((err) => this.handleError(vault, err));
  }

  /// Redeem the share tokens
  async redeem(vaultAddress: string, shares: BigNumber, receiver: string): Promise<void> {
    const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    await vault.redeem(shares, receiver, receiver).catch((err) => this.handleError(vault, err));
  }

  /// Get the instance of an asset associated with the vault
  async getAssetInstance(vaultAddress: string): Promise<ERC20> {
    const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    const assetAddress = await vault.asset().catch((err) => this.handleError(vault, err));
    return ERC20__factory.connect(assetAddress as string, this.signer);
  }

  /// Get the instance of the vault
  async getVaultInstance(vaultAddress: string): Promise<CredbullFixedYieldVault> {
    return CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
  }

  /// Get upside vault instance
  async getUpsideVaultInstance(vaultAddress: string): Promise<CredbullFixedYieldVaultWithUpside> {
    return CredbullFixedYieldVaultWithUpside__factory.connect(vaultAddress, this.signer);
  }

  async getTokenInstance(vaultAddress: string): Promise<ERC20> {
    const vault = CredbullFixedYieldVaultWithUpside__factory.connect(vaultAddress, this.signer);
    const tokenAddress = await vault.token().catch((err) => this.handleError(vault, err));
    return ERC20__factory.connect(tokenAddress as string, this.signer);
  }
}
