import {describe, it} from 'mocha';
import {assert} from 'chai';

import {ethers} from 'ethers';

import Safe, {EthersAdapter, SafeAccountConfig} from "@safe-global/protocol-kit";

import {SafeTransaction, SafeTransactionDataPartial, TransactionResult} from "@safe-global/safe-core-sdk-types";
import {deployVault} from "../src/utils/vault-utils";
import {SAFE_VERSION, TestSigner, TestSigners} from "./test-signer";
import {approveTransaction} from "../src/utils/transaction-utils";
import {AllowanceModule__factory,} from "../lib/safe-modules-master/allowances/typechain-types";
import execSafeTransaction from "../lib/safe-modules-master/allowances/test/test-helpers/execSafeTransaction";

const { Interface } = require("ethers").utils;

const ALLOWANCE_MODULE_ADDRESS_LOCAL = "0xE46FE78DBfCa5E835667Ba9dCd3F3315E7623F8a";

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

/// @dev Allows to update the allowance for a specified token. This can only be done via a Safe transaction.
/// @param delegate Delegate whose allowance should be updated.
/// @param token Token contract address.
/// @param allowanceAmount allowance in smallest token unit.
/// @param resetTimeMin Time after which the allowance should reset
/// @param resetBaseMin Time based on which the reset time should be increased
// function setAllowance(address delegate, address token, uint96 allowanceAmount, uint16 resetTimeMin, uint32 resetBaseMin) public {

const ABI_ADD_DELEGATE = [
    "function addDelegate(address delegate)",
    "function getAllowance(address safe, address delegate, address token)",
    "function setAllowance(address delegate, address token, uint96 allowanceAmount, uint16 resetTimeMin, uint32 resetBaseMin)",
    "function getTokens(address safe, address delegate)", // public view returns (address[] memory)
];

// See: https://github.com/safe-global/safe-core-sdk/tree/main/packages/protocol-kit
describe("Test a Vault with the Allowance module", () => {

    it("Parse the ABI of the Allowance addDelegate function", async function () {
        const contractInterface = new Interface(ABI_ADD_DELEGATE);
        let delegateAddress = await testSigners.cfoSigner.getAddress();

        // two different ways of getting the txnDataFromABI for the transaction

        // Option 1 - get the txnDataFromABI from the ABI
        const txnDataFromABI: string = contractInterface.encodeFunctionData("addDelegate", [delegateAddress]);

        // Option 2 - get the txnDataFromABI from the Allowance Module utils
        const allowanceModule = AllowanceModule__factory.connect(ALLOWANCE_MODULE_ADDRESS_LOCAL)
        let txnDataFromAllowanceUtils = (await allowanceModule.addDelegate.populateTransaction(delegateAddress)).data;

        // option 1 and 2 should be equivalent
        assert.equal(txnDataFromAllowanceUtils, txnDataFromABI)

        // use the ABI to decode the txnDataFromABI
        const parsedData = contractInterface.parseTransaction({
            data: txnDataFromABI,
        });

        assert.equal("addDelegate", parsedData.name)
        assert.equal(1, parsedData.args.length)
        assert.equal(delegateAddress, parsedData.args[0])

    });

    // create a multi-sig safe with a module
    it("Deploy a multi-sig safe and associate Allowance module", async function () {
        // setup - create and deploy a safe
        const safeAccountConfig: SafeAccountConfig = await testSigners.createSafeAccountConfig(2);
        const safe: Safe = await deployVault(safeAccountConfig, ethAdapter, SAFE_VERSION)

        // no modules should be associated to the vault (yet)
        assert.equal(0, (await safe.getModules()).length);
        const allowanceAddress: string = ALLOWANCE_MODULE_ADDRESS_LOCAL;
        assert.isNotTrue(await safe.isModuleEnabled(allowanceAddress))

        // setup - associate the module
        const safeTransaction: SafeTransaction = await safe.createEnableModuleTx(allowanceAddress)

        // sign and execute the createEnableModule transaction
        const approvers: TestSigner[] = [testSigners.ceoSigner, testSigners.cfoSigner];
        for (const approver of approvers) {
            await approveTransaction(await approver.getDelegate(), safe, safeTransaction);
        }
        await safe.executeTransaction(safeTransaction)

        // assert - verify the module is now enabled on the vault
        assert.isTrue(await safe.isModuleEnabled(allowanceAddress))
        const moduleAddresses: string[] = await safe.getModules()
        assert.equal(1, moduleAddresses.length);

        // TODO: now we can execute the module
        // 3. The module is ready to call the execTransactionFromModule function. Because now the module is enabled, this condition will pass.

        // both the safe and the allowance work by signature

        const contractInterface = new Interface(ABI_ADD_DELEGATE);

        // add a delegate // "function addDelegate(address delegate)",
        let aliceAsDelegateAddress: string = await new TestSigner(8, provider).getAddress(); // delegate to a signer with funds, but isn't a safe owner or allowance spender

        const addDelegateTransactionData: string = contractInterface.encodeFunctionData("addDelegate", [aliceAsDelegateAddress]);
        await executeSafeTransaction(safe, aliceAsDelegateAddress, addDelegateTransactionData, approvers);


        // get the delegate allowance // "function getAllowance(address safe, address delegate, address token)",
        // TODO: change to "call" the function to get the return valu.  Not available on the executeTransaction
        const safeAddress = await safe.getAddress();
        const tokenAddress: string = "0x0000000000000000000000000000000000000000"; // native token address

        const getDelegateAllowance: string = contractInterface.encodeFunctionData("getAllowance", [safeAddress, aliceAsDelegateAddress, tokenAddress]);
        const delegateAllowanceResult = await executeSafeTransaction(safe, aliceAsDelegateAddress, addDelegateTransactionData, approvers);

        let delegateAllowanceTxnReceipt = await delegateAllowanceResult.transactionResponse?.wait();
        assert.equal(1, delegateAllowanceTxnReceipt?.status) // 1 is success, (0 is failure)

    });


    // add alice as delegate

    // create an allowance for alice
    // await execSafeTransaction(
    //     safe,
    //     await allowanceModule.setAllowance.populateTransaction(
    //         alice.address,
    //         tokenAddress,
    //         100,
    //         0,
    //         0
    //     ),
    //     owner
    // )
    /*
    // create an allowance for alice
    await execSafeTransaction(
      safe,
      await allowanceModule.setAllowance.populateTransaction(
        alice.address,
        tokenAddress,
        100,
        0,
        0
      ),
      owner
    )
     */

    // TODO: test against previously deployed safe
    // const safeSdk = await Safe.create({ethAdapter, safeAddress})

});

/// @dev Allows to update the allowance for a specified token. This can only be done via a Safe transaction.
/// @param delegate Delegate whose allowance should be updated.
/// @param token Token contract address.
/// @param allowanceAmount allowance in smallest token unit.
/// @param resetTimeMin Time after which the allowance should reset
/// @param resetBaseMin Time based on which the reset time should be increased
// function setAllowance(address delegate, address token, uint96 allowanceAmount, uint16 resetTimeMin, uint32 resetBaseMin) public {

async function executeSafeTransaction(safe: Safe, delegateAddress: string, txnData: string, approvers: TestSigner[]) {

    const addDelegateTransaction = await safe.createTransaction({
        safeTransactionData: {
            to: delegateAddress,
            value: "0",
            data: txnData,
        }
    })

    // TODO: confirm which approvers are required.  should the transaction relate to the safe or the module?
    for (const approver of approvers) {
        await approveTransaction(await approver.getDelegate(), safe, addDelegateTransaction);
    }

    return await safe.executeTransaction(addDelegateTransaction)
}

