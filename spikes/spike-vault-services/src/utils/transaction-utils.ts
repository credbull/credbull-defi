import {Provider} from "@ethersproject/providers";
import Safe, {EthersAdapter} from "@safe-global/protocol-kit";
import {SafeTransaction, TransactionResult} from "@safe-global/safe-core-sdk-types";
import {ethers, Signer} from "ethers";

export async function approveTransaction(approver: Signer | Provider, safe: Safe, safeTransaction: SafeTransaction) {
    const ethAdapterSigner: EthersAdapter = new EthersAdapter({
        ethers,
        signerOrProvider: approver
    })

    const safeSdkApprover: Safe = await safe.connect({ethAdapter: ethAdapterSigner})
    const txHash: string = await safeSdkApprover.getTransactionHash(safeTransaction);

    return await safeSdkApprover.approveTransactionHash(txHash)
}

export async function signAndExecute(vault: Safe, safeTransaction: SafeTransaction, signers: Signer[]): Promise<{
    approvalTxnResults: TransactionResult[];
    executeTransactionResult: TransactionResult
}> {

    const approvalTxnResults: TransactionResult[] = [];

    // sign the transaction
    for (const signer of signers) {
        const approvalTxnResult: TransactionResult = await approveTransaction(signer, vault, safeTransaction);
        approvalTxnResults.push(approvalTxnResult)
    }

    // execute the transaction
    const executeTransactionResult: TransactionResult = await vault.executeTransaction(safeTransaction)

    return {approvalTxnResults: approvalTxnResults, executeTransactionResult: executeTransactionResult}
}
