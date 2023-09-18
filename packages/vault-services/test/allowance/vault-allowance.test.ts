import {describe, it} from 'mocha';
import {assert} from 'chai';

import {Contract, ethers, providers, Signer} from 'ethers';
import {LogDescription} from "ethers/lib/utils";

import Safe, {EthersAdapter} from "@safe-global/protocol-kit";

import {SafeTransaction, TransactionResult} from "@safe-global/safe-core-sdk-types";
import {deployVault, depositToSafe, toWei} from "../../src/utils/vault-utils";
import {SAFE_VERSION, TestSigner, TestSigners} from "../test-signer";
import {signAndExecute} from "../../src/utils/transaction-utils";
import {AllowanceModule__factory,} from "../../lib/safe-modules-master/allowances/typechain-types";
import {paramsToSign} from "./exec-allowance-transfer";

const {Interface} = require("ethers").utils;

const ALLOWANCE_MODULE_ADDRESS_LOCAL = "0xE46FE78DBfCa5E835667Ba9dCd3F3315E7623F8a";

const ABI_ALLOWANCE_MODULE = [
    "function addDelegate(address delegate)",
    "function getTokenAllowance(address safe, address delegate, address token) public view returns (uint256[5] memory)",
    "function setAllowance(address delegate, address token, uint96 allowanceAmount, uint16 resetTimeMin, uint32 resetBaseMin)",
    "function getTokens(address safe, address delegate) public view returns (address[] memory)",
    "function executeAllowanceTransfer(address safe, address token, address payable to, uint96 amount, address paymentToken, uint96 payment, address delegate, bytes signature)",

    "event AddDelegate(address indexed safe, address delegate)",
    "event RemoveDelegate(address indexed safe, address delegate)",
    "event ExecuteAllowanceTransfer(address indexed safe, address delegate, address token, address to, uint96 value, uint16 nonce)",
    "event PayAllowanceTransfer(address indexed safe, address delegate, address paymentToken, address paymentReceiver, uint96 payment)",
    "event SetAllowance(address indexed safe, address delegate, address token, uint96 allowanceAmount, uint16 resetTime)",
    "event ResetAllowance(address indexed safe, address delegate, address token)",
    "event DeleteAllowance(address indexed safe, address delegate, address token)",
];

const ALLOWANCE_CONTRACT_INTERFACE = new Interface(ABI_ALLOWANCE_MODULE);

const TOKEN_ADDRESS: string = "0x0000000000000000000000000000000000000000"; // native token address


var provider: ethers.providers.JsonRpcProvider;
var ethAdapter: EthersAdapter;
var testSigners: TestSigners;
var allowanceContract: Contract;

before(async () => {
    provider = new ethers.providers.JsonRpcProvider(); // no url, defaults to ``http:/\/localhost:8545`
    testSigners = new TestSigners(provider);

    ethAdapter = new EthersAdapter({
        ethers,
        signerOrProvider: testSigners.ceoSigner.getDelegate()
    })

    allowanceContract = new ethers.Contract(ALLOWANCE_MODULE_ADDRESS_LOCAL, ABI_ALLOWANCE_MODULE, provider);

})

class AllowanceParams {
    delegateAddress: string
    tokenAddress: string
    allowanceAmount: number

    constructor(delegateAddress: string, tokenAddress: string, allowanceAmount: number) {
        this.delegateAddress = delegateAddress;
        this.tokenAddress = tokenAddress;
        this.allowanceAmount = allowanceAmount;
    }
}

// See Safe Allowance Module: https://github.com/safe-global/safe-modules/tree/master/allowances
describe("Test a Vault with the Allowance module", () => {

    it("Parse the ABI of the Allowance addDelegate function", async function () {
        let delegateAddress = await testSigners.cfoSigner.getAddress();

        // two different ways of getting the txnDataFromABI for the transaction

        // Option 1 - get the txnDataFromABI from the ABI
        const delegateMethodName = "addDelegate";
        const txnDataFromABI: string = ALLOWANCE_CONTRACT_INTERFACE.encodeFunctionData(delegateMethodName, [delegateAddress]);

        // Option 2 - get the txnDataFromABI from the Allowance Module utils
        const allowanceModule = AllowanceModule__factory.connect(ALLOWANCE_MODULE_ADDRESS_LOCAL)
        const txnFromAllowanceUtils = await allowanceModule.addDelegate.populateTransaction(delegateAddress);

        assert.equal(ALLOWANCE_MODULE_ADDRESS_LOCAL, txnFromAllowanceUtils.to)

        // option 1 and 2 should be equivalent
        assert.equal(txnFromAllowanceUtils.data, txnDataFromABI)

        // use the ABI to decode the txnDataFromABI
        const parsedData = ALLOWANCE_CONTRACT_INTERFACE.parseTransaction({
            data: txnDataFromABI,
        });

        assert.equal(delegateMethodName, parsedData.name)
        assert.equal(1, parsedData.args.length)
        assert.equal(delegateAddress, parsedData.args[0])

    });


    // create a multi-sig safe with a module
    it("Test granting a Token Allowance to a someone not an owner of the Safe", async function () {
        const allowanceAddress = ALLOWANCE_MODULE_ADDRESS_LOCAL;
        const safe: Safe = await deployVault(await testSigners.createSafeAccountConfig(2), ethAdapter, SAFE_VERSION)

        // no modules should be associated to the vault (yet)
        assert.equal(0, (await safe.getModules()).length);
        assert.isNotTrue(await safe.isModuleEnabled(allowanceAddress))

        // setup - associate the module
        const safeTransaction: SafeTransaction = await safe.createEnableModuleTx(allowanceAddress)

        // sign and execute the createEnableModule transaction
        const approvers: Signer[] = [testSigners.ceoSigner.getDelegate(), testSigners.cfoSigner.getDelegate()];
        await signAndExecute(safe, safeTransaction, approvers);

        // assert - verify the module is now enabled on the vault
        assert.isTrue(await safe.isModuleEnabled(allowanceAddress))
        const moduleAddresses: string[] = await safe.getModules()
        assert.equal(1, moduleAddresses.length);


        // add a delegate // "function addDelegate(address delegate)",
        const safeAddress = await safe.getAddress();
        let delegateSigner: TestSigner = await new TestSigner(8, provider); // delegate to a signer with funds, but isn't a safe owner or allowance spender
        let delegateAddress: string = await delegateSigner.getAddress();

        await addDelegateAndVerify(safe, allowanceAddress, delegateAddress, approvers);

        // grant delegate an allowance on a token
        const delegateAllowanceParams = new AllowanceParams(delegateAddress, TOKEN_ADDRESS, 100)
        await setTokenAllowanceAndVerify(safe, allowanceAddress, delegateAllowanceParams, approvers);

        // delegate has an allowance, but no tokens
        const delegateTokenAmount = await getTokens(safeAddress, delegateAddress)
        assert.equal(0, delegateTokenAmount);


        // okay - lets actually do transfers!
        const execAllowanceParams = new AllowanceParams(delegateAddress, TOKEN_ADDRESS, 1)
        await execAllocationAndVerify(safe, allowanceAddress, execAllowanceParams);
    });
});


async function logTransactionEvents(transactionResult: TransactionResult, contract: Contract) {
    const setAllowanceTxnReceipt = await transactionResult.transactionResponse?.wait();

    if (!setAllowanceTxnReceipt) throw new Error("No receipt")

    return setAllowanceTxnReceipt.logs
        .filter(log => log.address.toLowerCase() === contract.address.toLowerCase())
        .map(log => {
            try {
                return contract.interface.parseLog(log as providers.Log);
            } catch (error) {
                console.error("Failed to parse log:", log);
                return null;
            }
        })
        .filter((parsedLog): parsedLog is LogDescription => parsedLog !== null);
}


async function addDelegateAndVerify(safe: Safe, allowanceAddress: string, delegateAddress: string, approvers: Signer[]) {
    const addDelegateTransaction = await safe.createTransaction({
        safeTransactionData: {
            to: allowanceAddress,
            value: "0",
            data: ALLOWANCE_CONTRACT_INTERFACE.encodeFunctionData("addDelegate", [delegateAddress]),
        }
    })
    const addDelegateTxnResult = await signAndExecute(safe, addDelegateTransaction, approvers);//await signAndExecuteTransaction(safe, allowanceAddress, addDelegateTransactionData, approvers);
    assert.equal(1, (await addDelegateTxnResult.executeTransactionResult.transactionResponse?.wait())?.status) // 1 is success, (0 is failure)

    // verify the Add Delegate transaction was success by checking the Event logs
    const addDelegateLog = await logTransactionEvents(addDelegateTxnResult.executeTransactionResult, allowanceContract);
    assert.equal(1, addDelegateLog.length)
    assert.equal("AddDelegate", addDelegateLog[0].name)

    return addDelegateTxnResult;
}


async function verifyAllowance(safeAddress: string, allowanceParams: AllowanceParams, expectedAllowance: number) {
    const tokenAllowance = await allowanceContract.getTokenAllowance(safeAddress, allowanceParams.delegateAddress, allowanceParams.tokenAddress);

    assert.equal(tokenAllowance[0].toNumber(), expectedAllowance)
}

async function getTokens(safeAddress: string, delegateAddress: string) {
    const getTokensResult = await allowanceContract.getTokens(safeAddress, delegateAddress);
    const tokens = getTokensResult[0]
    return tokens;
}


async function setTokenAllowanceAndVerify(safe: Safe, allowanceAddress: string, allowanceParams: AllowanceParams, approvers: Signer[]) {
    // set up a token allowance
    const safeAddress: string = await safe.getAddress();

    // using ethers.js in order to read the returns value.  SafeSDK only returning the transactional data.
    const tokenAllowanceBefore = await allowanceContract.getTokenAllowance(safeAddress, allowanceParams.delegateAddress, allowanceParams.tokenAddress);
    assert.equal(tokenAllowanceBefore[0].toNumber(), 0)

    const setAllowanceTransaction = await safe.createTransaction({
        safeTransactionData: {
            to: allowanceAddress,
            value: "0",
            data: ALLOWANCE_CONTRACT_INTERFACE.encodeFunctionData("setAllowance", [allowanceParams.delegateAddress, allowanceParams.tokenAddress, allowanceParams.allowanceAmount, 0, 0])
        }
    })

    const setAllowanceTxnResult = await signAndExecute(safe, setAllowanceTransaction, approvers)
    assert.equal(1, (await setAllowanceTxnResult.executeTransactionResult.transactionResponse?.wait())?.status) // 1 is success, (0 is failure)

    // check the token allowance
    await verifyAllowance(safeAddress, allowanceParams, allowanceParams.allowanceAmount);

    return setAllowanceTxnResult
}

async function execAllocationAndVerify(safe: Safe, allowanceAddress: string, delegateAllowanceParams: AllowanceParams) {
    const delegateAddress: string = delegateAllowanceParams.delegateAddress

    // top up the safe with some precious ducats
    assert.equal((await safe.getBalance()).toNumber(), 0);
    const depositAmountInEther: number = 10;
    await depositToSafe(provider, await safe.getAddress(), await testSigners.investorSigner.getAddress(), depositAmountInEther);
    assert.equal((await safe.getBalance()).toBigInt(), toWei(depositAmountInEther));

    // alright, so we want to give some tokens to a random person
    let bobSigner: TestSigner = await new TestSigner(9, provider); // delegate to a signer with funds, but isn't a safe owner or allowance spender

    const bobBalanceBefore: bigint = await bobSigner.getBalance();

    // check before
    const delegateWalletPK = "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97";
    const delegateWallet = new ethers.Wallet(delegateWalletPK, provider) // TODO - temporary, try to remove this.
    assert.equal(delegateWallet.address, delegateAddress)

    const chainId = BigInt(31337); // TODO - temp, remove this if possible
    const [, , , , nonce] = await allowanceContract.getTokenAllowance((await safe.getAddress()), delegateAddress, TOKEN_ADDRESS)

    const paramsToSignParams = {
        safe: (await safe.getAddress()),
        token: delegateAllowanceParams.tokenAddress,
        to: (await bobSigner.getAddress()),
        amount: delegateAllowanceParams.allowanceAmount
    }

    // Sign the message using the EIP-712 format
    const {domain, types, message} = paramsToSign(allowanceAddress, BigInt(chainId), paramsToSignParams, nonce)
    const signatureFromSignTypedData = await delegateWallet._signTypedData(domain, types, message);

    // execute the allowance transfer
    const executeAllowanceTxn = await allowanceContract.populateTransaction.executeAllowanceTransfer(
        (await safe.getAddress()), // OK - safe
        delegateAllowanceParams.tokenAddress, // OK - token address
        (await bobSigner.getAddress()), // OK - payable to
        delegateAllowanceParams.allowanceAmount, // OK - amount
        TOKEN_ADDRESS, // OK - payment token
        0, // OK - payment
        delegateAddress, // OK - spender address
        signatureFromSignTypedData // signature bytes ??? // ??? signature : SignerWithAddress
    )

    const executeAllowanceTxnResponse = await delegateWallet.sendTransaction(executeAllowanceTxn);
    const executeAllowanceTxnReceipt = await executeAllowanceTxnResponse.wait();
    assert.equal(1, executeAllowanceTxnReceipt.status)

    // verify after
    const bobBalanceAfter: bigint = await bobSigner.getBalance();
    assert.equal(bobBalanceAfter, (bobBalanceBefore + BigInt(delegateAllowanceParams.allowanceAmount)))
}


