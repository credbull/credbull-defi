import {describe, it} from 'mocha';
import {assert} from 'chai';

import {Contract, ethers} from 'ethers';

import Safe, {EthersAdapter, SafeAccountConfig} from "@safe-global/protocol-kit";

import {SafeTransaction, TransactionResult} from "@safe-global/safe-core-sdk-types";
import {deployVault} from "../src/utils/vault-utils";
import {SAFE_VERSION, TestSigner, TestSigners} from "./test-signer";
import {approveTransaction} from "../src/utils/transaction-utils";
import {AllowanceModule__factory,} from "../lib/safe-modules-master/allowances/typechain-types";

const {Interface} = require("ethers").utils;

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


const ABI_ALLOWANCE_MODULE = [
    "function addDelegate(address delegate)",
    "function getTokenAllowance(address safe, address delegate, address token) public view returns (uint256[5] memory)",
    "function setAllowance(address delegate, address token, uint96 allowanceAmount, uint16 resetTimeMin, uint32 resetBaseMin)",
    "function getTokens(address safe, address delegate) public view returns (address[] memory)",
    "event AddDelegate(address indexed safe, address delegate)",
    "event RemoveDelegate(address indexed safe, address delegate)",
    "event ExecuteAllowanceTransfer(address indexed safe, address delegate, address token, address to, uint96 value, uint16 nonce)",
    "event PayAllowanceTransfer(address indexed safe, address delegate, address paymentToken, address paymentReceiver, uint96 payment)",
    "event SetAllowance(address indexed safe, address delegate, address token, uint96 allowanceAmount, uint16 resetTime)",
    "event ResetAllowance(address indexed safe, address delegate, address token)",
    "event DeleteAllowance(address indexed safe, address delegate, address token)",
];


// See Safe Allowance Module: https://github.com/safe-global/safe-modules/tree/master/allowances
describe("Test a Vault with the Allowance module", () => {

    it("Parse the ABI of the Allowance addDelegate function", async function () {
        const contractInterface = new Interface(ABI_ALLOWANCE_MODULE);
        let delegateAddress = await testSigners.cfoSigner.getAddress();

        // two different ways of getting the txnDataFromABI for the transaction

        // Option 1 - get the txnDataFromABI from the ABI
        const delegateMethodName = "addDelegate";
        const txnDataFromABI: string = contractInterface.encodeFunctionData(delegateMethodName, [delegateAddress]);

        // Option 2 - get the txnDataFromABI from the Allowance Module utils
        const allowanceModule = AllowanceModule__factory.connect(ALLOWANCE_MODULE_ADDRESS_LOCAL)
        const txnFromAllowanceUtils = await allowanceModule.addDelegate.populateTransaction(delegateAddress);
        let txnDataFromAllowanceUtils = txnFromAllowanceUtils.data;

        console.log(`Allowance Addr ${ALLOWANCE_MODULE_ADDRESS_LOCAL}`)
        console.log(`Delegate Addr ${delegateAddress}`)

        assert.equal(ALLOWANCE_MODULE_ADDRESS_LOCAL, txnFromAllowanceUtils.to)

        // option 1 and 2 should be equivalent
        assert.equal(txnDataFromAllowanceUtils, txnDataFromABI)

        // use the ABI to decode the txnDataFromABI
        const parsedData = contractInterface.parseTransaction({
            data: txnDataFromABI,
        });

        assert.equal(delegateMethodName, parsedData.name)
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

        const contractInterface = new Interface(ABI_ALLOWANCE_MODULE);

        // add a delegate // "function addDelegate(address delegate)",
        let aliceAsDelegateAddress: string = await new TestSigner(8, provider).getAddress(); // delegate to a signer with funds, but isn't a safe owner or allowance spender

        const addDelegateTransactionData: string = contractInterface.encodeFunctionData("addDelegate", [aliceAsDelegateAddress]);
        const addDelegateTxnResult = await signAndExecuteTransaction(safe, allowanceAddress, addDelegateTransactionData, approvers);
        assert.equal(1, (await addDelegateTxnResult.transactionResponse?.wait())?.status) // 1 is success, (0 is failure)

        // TODO: add assert that the delegate is set

        const safeAddress: string = await safe.getAddress();
        const tokenAddress: string = "0x0000000000000000000000000000000000000000"; // native token address

        // using ethers.js in order to read the returns value.  SafeSDK only returning the transactional data.
        const contract = new ethers.Contract(allowanceAddress, ABI_ALLOWANCE_MODULE, provider);

        const tokenAllowanceBefore = await contract.getTokenAllowance(safeAddress, aliceAsDelegateAddress, tokenAddress);
        console.log(`Token Allowance Before = ${tokenAllowanceBefore}`)
        assert.equal(tokenAllowanceBefore[0].toNumber(), 0)

        // set the token allowance
        const tokenAllowance = 100;
        const setAllowance: string = contractInterface.encodeFunctionData("setAllowance", [aliceAsDelegateAddress, tokenAddress, tokenAllowance, 0, 0]);
        const setAllowanceTxnResult = await signAndExecuteTransaction(safe, allowanceAddress, setAllowance, approvers); // aliceAsDelegateAddress looks suspicious.  should this be safe or module address instead?
        assert.equal(1, (await setAllowanceTxnResult.transactionResponse?.wait())?.status) // 1 is success, (0 is failure)

        // check the token allowance
        const tokenAllowanceAfter = await contract.getTokenAllowance(safeAddress, aliceAsDelegateAddress, tokenAddress);
        console.log(`Token Allowance After = ${tokenAllowanceAfter}`)
        assert.equal(tokenAllowanceAfter[0].toNumber(), tokenAllowance)
    });
});

async function signAndExecuteTransaction(safe: Safe, toAddress: string, txnData: string, approvers: TestSigner[]) {

    const safeTransaction = await safe.createTransaction({
        safeTransactionData: {
            to: toAddress,
            value: "0",
            data: txnData,
        }
    })

    for (const approver of approvers) {
        await approveTransaction(await approver.getDelegate(), safe, safeTransaction);
    }

    return await safe.executeTransaction(safeTransaction)
}
