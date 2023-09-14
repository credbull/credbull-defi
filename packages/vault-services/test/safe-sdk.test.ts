import {describe, it} from 'mocha';
import {assert} from 'chai';

import {ethers, Wallet} from 'ethers';

import Safe, {ContractNetworksConfig, EthersAdapter, SafeAccountConfig, SafeFactory} from "@safe-global/protocol-kit";

import {AllSigners, MySigner} from "../src/my-signer";
import {createContractNetworks, SAFE_V130} from "../src/network-config";
import {
    SafeTransaction,
    SafeTransactionDataPartial,
    SafeVersion,
    TransactionResult
} from "@safe-global/safe-core-sdk-types";
import {JsonRpcSigner} from "@ethersproject/providers";

const OWNER_PUBLIC_KEY_LOCAL: string = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const ALLOWANCE_MODULE_ADDRESS_LOCAL="0xE46FE78DBfCa5E835667Ba9dCd3F3315E7623F8a";

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

        assert.equal(await owner.getAddress(), OWNER_PUBLIC_KEY_LOCAL);
    });

    it("EthersAdapter signer address should be the first account", async () => {
        assert.equal(await ethAdapter.getSignerAddress(), OWNER_PUBLIC_KEY_LOCAL);
    });

    // create a multi-sign safe
    it("Deploy a multi-sig safe", async function () {
        // create and deploy a safe
        const treasury: Safe = await deployTreasury(3);
        const treasuryAddress = await treasury.getAddress();

        assert.notEqual(treasuryAddress, "0x0");
        assert.equal((await treasury.getBalance()).toNumber(), 0);
    });

    // create a multi-sig safe with a module
    it("Deploy a multi-sig safe and associate Allowance module", async function () {
        // setup - create and deploy a safe
        const treasury: Safe = await deployTreasury(2);

        // no modules should be associated to the vault (yet)
        assert.equal(0, (await treasury.getModules()).length);
        const moduleAddress: string = ALLOWANCE_MODULE_ADDRESS_LOCAL;
        assert.isNotTrue(await treasury.isModuleEnabled(moduleAddress))

        // setup - associate the module
        const safeTransaction: SafeTransaction = await treasury.createEnableModuleTx(moduleAddress)

        // sign and execute the createEnableModule transaction
        const approvers: MySigner[] = [allSigners.ceoSigner, allSigners.cfoSigner];
        for (const approver of approvers) {
            await approveTransaction(await approver.getDelegate(), treasury, safeTransaction);
        }
        await treasury.executeTransaction(safeTransaction)

        // assert - verify the module is now enabled on the vault
        assert.isTrue(await treasury.isModuleEnabled(moduleAddress))
        const moduleAddresses: string[] = await treasury.getModules()
        assert.equal(1, moduleAddresses.length);


        // TODO: now we can execute the module
        // 3. The module is ready to call the execTransactionFromModule function. Because now the module is enabled, this condition will pass.
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

        // sign the transaction
        const approvers: MySigner[] = [allSigners.ceoSigner, allSigners.cfoSigner, allSigners.ctoSigner];
        for (const approver of approvers) {
            const approvalTxnResult: TransactionResult = await approveTransaction(await approver.getDelegate(), treasury, safeTransaction);
            assert.equal(1, (await approvalTxnResult.transactionResponse?.wait())?.status) // 1 is success, (0 is failure)
        }

        // execute the transaction
        const executeTxResponse = await treasury.executeTransaction(safeTransaction)
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
