import { ServiceResponse } from "@credbull/api";
import { Tables } from "@credbull/api";
import { BigNumber, Signer, providers } from 'ethers';
import { CredbullFixedYieldVault__factory, MockStablecoin__factory  } from "@credbull/contracts";
import { decodeError } from "./mock/utils/helpers";

export class CredbullSDK {
    private SERVICE_URL = 'http://localhost:3001';
    constructor(private access_token: string, private signer: Signer | providers.Provider) {
    }

    private headers() {
        return {
            headers: {
                'Content-Type': 'application/json',
                ...(this.access_token ? { Authorization: `Bearer ${this.access_token}` } : {}),
            },
        };
    };

    /// Return all active vaults
    async getAllVaults(): Promise<ServiceResponse<Tables<'vaults'>[]>> {
        const vaultsData = await fetch(`${this.SERVICE_URL}/vaults/current`, { method: 'GET', ...this.headers() });
        return await vaultsData.json();
    }

    /// Link user wallet
    async linkWallet(message: string, signature: string, discriminator?: string): Promise<ServiceResponse<Tables<'user_wallets'>[]>> {
        const linkWallet = await fetch(`${this.SERVICE_URL}/accounts/link-wallet`, {
            method: 'POST',
            body: JSON.stringify({ message, signature, discriminator }),
            ...this.headers()
        });

        return await linkWallet.json();
    }

    /// Deposit token to the given vault address
    async deposit(vaultAddress: string, amount: BigNumber, receiver: string) {
        const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
        return await vault.deposit(amount, receiver);
    }

    /// Redeem the share tokens
    async redeem(vaultAddress: string, shares: BigNumber, receiver: string) {
        const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
        const res = await vault.redeem(shares, receiver, receiver);
        await res.wait();
    }

    /// Get the instance of an asset associated with the vault
    async getAssetInstance(vaultAddress: string) {
        const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
        const assetAddress =  await vault.asset();

        return MockStablecoin__factory.connect(assetAddress, this.signer);
    }

    /// Get the instance of the vault
    async getVaultInstance(vaultAddress: string) {
        return CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    }
}