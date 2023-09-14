import {describe, it} from 'mocha';
import {assert} from 'chai';

import {ethers, Wallet} from 'ethers';

import Safe, {
    ContractNetworksConfig,
    EthersAdapter,
    SafeAccountConfig,
    SafeFactory
} from "@safe-global/protocol-kit";

import {AllSigners, MySigner} from "../src/my-signer";
import {createContractNetworks, SAFE_V130} from "../src/network-config";
import {SafeTransaction, SafeTransactionDataPartial, SafeVersion, TransactionResult} from "@safe-global/safe-core-sdk-types";
import {JsonRpcSigner} from "@ethersproject/providers";

const OWNER_PUBLIC_KEY: string = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const SAFE_VERSION: SafeVersion = SAFE_V130;

var provider: ethers.providers.JsonRpcProvider;
var ethAdapter: EthersAdapter;
var allSigners: AllSigners;

before(async () => {
    provider = new ethers.providers.JsonRpcProvider(); // no url, defaults to ``http:/\/localhost:8545`
    allSigners = new AllSigners(provider);

    ethAdapter = new EthersAdapter({
        ethers,
        signerOrProvider: allSigners.ceoSigner.getDelegate()
    })
})

async function deployTreasury(threshold: number): Promise<Safe> {
    var contractNetworks: ContractNetworksConfig = createContractNetworks(await ethAdapter.getChainId(), SAFE_VERSION);
    
    const safeFactory: SafeFactory = await SafeFactory.create({
        ethAdapter: ethAdapter,
        contractNetworks: contractNetworks,
        safeVersion: SAFE_VERSION
    });

    const safeAccountConfig: SafeAccountConfig = await allSigners.createSafeAccountConfig(threshold);

    // TODO: review nonce behaviour, see const nonce = await safeService.getNextNonce(safeAddress) https://docs.safe.global/reference/api-kit
    const saltNonce: string = Date.now().toString(); // using a salt, otherwise fails on multiple calls (all other params the same)

    const safeSdk: Safe = await safeFactory.deploySafe({safeAccountConfig, saltNonce})

    return safeSdk;
}


function toEtherHex(value: string) {
    return ethers.utils.parseUnits(value, "ether").toHexString();
}


// See: https://github.com/safe-global/safe-core-sdk/tree/main/packages/protocol-kit
describe("Test the Safe SDK", () => {

    it("Create a signer from the first account", async () => {
        const owner = new MySigner(0, provider).getDelegate();

        assert.equal(await owner.getAddress(), OWNER_PUBLIC_KEY);
    });

    it("EthersAdapter signer address should be the first account", async () => {
        assert.equal(await ethAdapter.getSignerAddress(), OWNER_PUBLIC_KEY);
    });

    // create a multi-sign safe
    it("Deploy a multi-sig safe", async function () {
        // create and deploy a safe
        const treasury: Safe = await deployTreasury(3);
        const treasuryAddress = await treasury.getAddress();

        assert.notEqual(treasuryAddress, "0x0");
        assert.equal((await treasury.getBalance()).toNumber(), 0);
    });

    // create a multi-sig safe with a Strategy module
    // TODO: add this test (deploy module and associate to safe)
    it.skip("Deploy a multi-sig safe and associate Allowance module", async function () {
        // create and deploy a safe
        const treasury: Safe = await deployTreasury(3);
        const treasuryAddress = await treasury.getAddress();

        assert.notEqual(treasuryAddress, "0x0");
        assert.equal((await treasury.getBalance()).toNumber(), 0);

        // check that depositing works
        // ============= investor deposits 10
        const investorAddress: string = await allSigners.investorSigner.getAddress();
        const depositValue: string = toEtherHex("10");

        // create and authorize a transaction
        const params = [{
            from: investorAddress,
            to: treasuryAddress,
            value: depositValue,
        }];

        let depositResult1 = await provider.send("eth_sendTransaction", params);
        assert.equal((await treasury.getBalance()).toHexString(), depositValue);


        // associate a module to the vault
        // e.g. allowance module

        // The ModuleManager.sol contract handles the admin actions regarding modules, like enable/disable modules, executing transactions via a module, checking if a module is enabled, etc.
        //
        // These are the steps you need to follow to enable a module:
        // 1. Call the enableModule function. It has the modifier authorized so you need to call it by executing a transaction from your Safe.
        // 2. Optionally you can check if the module is already enabled by calling isModuleEnabled function.
        // 3. The module is ready to call the execTransactionFromModule function. Because now the module is enabled, this condition will pass.

        const moduleAddress = "0x0";  // TODO: use the real module address

        const safeTransaction = await treasury.createEnableModuleTx(moduleAddress)
        const txResponse = await treasury.executeTransaction(safeTransaction)
        await txResponse.transactionResponse?.wait()

        const moduleAddresses: string[] = await treasury.getModules()
        assert.isTrue(moduleAddresses.length > 0);

//        const isEnabled = await treasury.isModuleEnabled(moduleAddress)


        let depositResult2 = await provider.send("eth_sendTransaction", params); // this should fail
        assert.equal((await treasury.getBalance()).toHexString(), toEtherHex("10"));

        // check that deposits no longer allowed
    });

    // sign with multi-sig safe
    it("Deposit 10 Eth into Safe and Sign with Threshold 3", async function () {
        // create and deploy a safe
        const treasury: Safe = await deployTreasury(3);
        const treasuryAddress: string = await treasury.getAddress();


        // ============= investor deposits 10
        const investorAddress: string = await allSigners.investorSigner.getAddress();
        const depositValue: string = toEtherHex("10");

        // create and authorize a transaction
        const params = [{
            from: investorAddress,
            to: treasuryAddress,
            value: depositValue,
        }];

        let result = await provider.send("eth_sendTransaction", params);

        assert.equal((await treasury.getBalance()).toHexString(), depositValue);

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

        const safeTransaction: SafeTransaction = await treasury.createTransaction({safeTransactionData})

        // approver 1
        const approver1Result: TransactionResult = await approveTransaction(await allSigners.ceoSigner.getDelegate(), treasury, safeTransaction);
        // TODO: add assert  on this result

        // approver 2
        const approver2Result: TransactionResult = await approveTransaction(await allSigners.cfoSigner.getDelegate(), treasury, safeTransaction);
        // TODO: add assert  on this result

        // approver 3 - and execute
        const ethAdapterOwner3 = new EthersAdapter({
            ethers,
            signerOrProvider: (await allSigners.ctoSigner.getDelegate())
        })

        // const safeSdk3 = await safeSdk2.connect({ ethAdapter: ethAdapterOwner3})
        const safeSdk3 = await treasury.connect({ethAdapter: ethAdapterOwner3})

        const executeTxResponse = await safeSdk3.executeTransaction(safeTransaction)
        await executeTxResponse.transactionResponse?.wait()

        assert.equal((await provider.getBalance(receivingWallet.address)).toHexString(), transferValue);
        assert.equal((await treasury.getBalance()).toHexString(), toEtherHex("7")); // todo: don't hardcode (but 10 - 3)
    });


    // TODO: test against previously deployed safe
    // const safeSdk = await Safe.create({ethAdapter, safeAddress})

});

async function approveTransaction(approver: JsonRpcSigner, treasury: Safe, safeTransaction: SafeTransaction) {
    const ethAdapterSigner: EthersAdapter = new EthersAdapter({
        ethers,
        signerOrProvider: approver
    })

    const safeSdkApprover: Safe = await treasury.connect({ethAdapter: ethAdapterSigner})
    const txHash: string = await safeSdkApprover.getTransactionHash(safeTransaction);

    return await safeSdkApprover.approveTransactionHash(txHash)
}
