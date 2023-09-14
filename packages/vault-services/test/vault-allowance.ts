import {describe, it} from 'mocha';
import {assert} from 'chai';

import {ethers, Wallet} from 'ethers';

import Safe, {EthersAdapter, SafeAccountConfig} from "@safe-global/protocol-kit";

import {MySigner} from "../src/my-signer";
import {
    SafeTransaction,
} from "@safe-global/safe-core-sdk-types";
import {deployVault, toEtherHex} from "../src/utils/vault-utils";
import {SAFE_VERSION, TestSigners} from "./test-fixture";
import {approveTransaction} from "../src/utils/transaction-utils";

const ALLOWANCE_MODULE_ADDRESS_LOCAL="0xE46FE78DBfCa5E835667Ba9dCd3F3315E7623F8a";

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
describe("Test a Vault with the Allowance module", () => {

    // create a multi-sig safe with a module
    it("Deploy a multi-sig safe and associate Allowance module", async function () {
        // setup - create and deploy a safe
        const safeAccountConfig: SafeAccountConfig = await testSigners.createSafeAccountConfig(2);
        const vault: Safe = await deployVault(safeAccountConfig, ethAdapter, SAFE_VERSION)

        // no modules should be associated to the vault (yet)
        assert.equal(0, (await vault.getModules()).length);
        const moduleAddress: string = ALLOWANCE_MODULE_ADDRESS_LOCAL;
        assert.isNotTrue(await vault.isModuleEnabled(moduleAddress))

        // setup - associate the module
        const safeTransaction: SafeTransaction = await vault.createEnableModuleTx(moduleAddress)

        // sign and execute the createEnableModule transaction
        const approvers: MySigner[] = [testSigners.ceoSigner, testSigners.cfoSigner];
        for (const approver of approvers) {
            await approveTransaction(await approver.getDelegate(), vault, safeTransaction);
        }
        await vault.executeTransaction(safeTransaction)

        // assert - verify the module is now enabled on the vault
        assert.isTrue(await vault.isModuleEnabled(moduleAddress))
        const moduleAddresses: string[] = await vault.getModules()
        assert.equal(1, moduleAddresses.length);


        // TODO: now we can execute the module
        // 3. The module is ready to call the execTransactionFromModule function. Because now the module is enabled, this condition will pass.
    });


    // TODO: test against previously deployed safe
    // const safeSdk = await Safe.create({ethAdapter, safeAddress})

});

