import { BigNumber, Signer } from 'ethers';
import { CredbullFixedYieldVault__factory, ERC20__factory } from "@credbull/contracts";
import { SiweMessage, generateNonce } from 'siwe';

export class CredbullSDK {
    private SERVICE_URL = 'http://localhost:3001';
    constructor(private access_token: string, private signer: Signer) {
    }

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
    };

    /// Return all active vaults
    async getAllVaults() {
        const vaultsData = await fetch(`${this.SERVICE_URL}/vaults/current`, { method: 'GET', ...this.headers() });
        return await vaultsData.json();
    }

    /// Link user wallet
    async linkWallet(discriminator?: string) {
        const message = await this.linkWalletMessage(this.signer);
        const signature = await this.signer.signMessage(message);

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
        await vault.redeem(shares, receiver, receiver);
    }

    /// Get the instance of an asset associated with the vault
    async getAssetInstance(vaultAddress: string) {
        const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
        const assetAddress = await vault.asset();

        return ERC20__factory.connect(assetAddress, this.signer);
    }

    /// Get the instance of the vault
    async getVaultInstance(vaultAddress: string) {
        return CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    }
}
