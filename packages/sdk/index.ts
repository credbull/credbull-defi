import { ServiceResponse } from "@credbull/api";
import { Tables } from "@credbull/api";
import { BigNumber, Signer } from 'ethers';
import { CredbullFixedYieldVault__factory  } from "@credbull/contracts";

export class CredbullSDK {
    private SERVICE_URL = 'http://localhost:3001';
    constructor(private access_token: string, private signer: Signer) { }

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
    async deposit(vaultAddress: string, amount: BigNumber) {
        const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
        return await vault.deposit(amount, await this.signer.getAddress());
    }

    async redeem(vaultAddress: string, shares: BigNumber) {
        const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
        const receiver = await this.signer.getAddress();
        // await vault.estimateGas.redeem(shares, receiver, receiver);
        const res = await vault.redeem(shares, receiver, receiver);
        await res.wait();
    }

    /// Returns the asset address associated with vault
    async getAssetAddress(vaultAddress: string) {
        const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
        return await vault.asset(); 
    }

    async getVaultInstance(vaultAddress: string) {
        return CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    }
}