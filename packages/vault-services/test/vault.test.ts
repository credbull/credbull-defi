import {describe, it} from 'mocha';
import {assert} from 'chai';

import {ethers, Wallet} from 'ethers';

import Safe, {EthersAdapter, SafeAccountConfig} from "@safe-global/protocol-kit";

import {SafeTransaction, SafeTransactionDataPartial} from "@safe-global/safe-core-sdk-types";
import {deployVault, depositToSafe, toEtherHex, toWei} from "../src/utils/vault-utils";
import {OWNER_PUBLIC_KEY_LOCAL, SAFE_VERSION, TestSigner, TestSigners} from "./test-signer";
import {signAndExecute} from "../src/utils/transaction-utils";

var provider: ethers.providers.JsonRpcProvider;
var ethAdapter: EthersAdapter;
var testSigners: TestSigners;

before(async () => {
    provider = new ethers.providers.JsonRpcProvider(); // no url, defaults to ``http:/\/localhost:8545`
    testSigners = new TestSigners(provider);

    ethAdapter = new EthersAdapter({
        ethers,
        signerOrProvider: testSigners.ceoSigner.getDelegate()
    })
})


// See: https://github.com/safe-global/safe-core-sdk/tree/main/packages/protocol-kit
describe("Test the Safe SDK", () => {

    it("Create a signer from the first account", async () => {
        const owner = new TestSigner(0, provider).getDelegate();

        assert.equal(await owner.getAddress(), OWNER_PUBLIC_KEY_LOCAL);
    });

    it("EthersAdapter signer address should be the first account", async () => {
        assert.equal(await ethAdapter.getSignerAddress(), OWNER_PUBLIC_KEY_LOCAL);
    });

    // create a multi-sign safe
    it("Deploy a multi-sig safe", async function () {
        // create and deploy a safe
        const safeAccountConfig: SafeAccountConfig = await testSigners.createSafeAccountConfig(3);
        const vault: Safe = await deployVault(safeAccountConfig, ethAdapter, SAFE_VERSION)
        const vaultAddress = await vault.getAddress();

        assert.notEqual(vaultAddress, "0x0");
        assert.equal((await vault.getBalance()).toNumber(), 0);
    });

    // sign with multi-sig safe
    it("Deposit 10 Eth into Safe and Sign with Threshold 3", async function () {
        // create and deploy a safe
        const safeAccountConfig: SafeAccountConfig = await testSigners.createSafeAccountConfig(3);
        const vault: Safe = await deployVault(safeAccountConfig, ethAdapter, SAFE_VERSION)
        const vaultAddress: string = await vault.getAddress();

        // ============= investor deposits 10
        const investorAddress: string = await testSigners.investorSigner.getAddress();

        const depositAmountInEther: number = 10;
        await depositToSafe(provider, vaultAddress, investorAddress, depositAmountInEther);
        assert.equal((await vault.getBalance()).toBigInt(), toWei(depositAmountInEther));

        // ===== transfer using multi-sig approvals  =====

        // give money to a random wallet
        const receivingWallet: Wallet = ethers.Wallet.createRandom();
        assert.equal((await provider.getBalance(receivingWallet.address)).toString(), "0");
        const transferValue = toEtherHex("3");

        const safeTransactionData: SafeTransactionDataPartial = {
            to: receivingWallet.address,
            value: transferValue,
            data: '0x'
        }

        const safeTransaction: SafeTransaction = await vault.createTransaction({safeTransactionData})
        const transactionResults = await signAndExecute(vault, safeTransaction, [testSigners.ceoSigner.getDelegate(), testSigners.cfoSigner.getDelegate(), testSigners.ctoSigner.getDelegate()]);

        assert.equal((await provider.getBalance(receivingWallet.address)).toHexString(), transferValue);
        assert.equal((await vault.getBalance()).toHexString(), toEtherHex("7")); // todo: don't hardcode (but 10 - 3)
    });

    // TODO: test against previously deployed safe
    // const safeSdk = await Safe.create({ethAdapter, safeAddress})


});
