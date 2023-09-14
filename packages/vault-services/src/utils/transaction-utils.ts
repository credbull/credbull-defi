import {JsonRpcSigner} from "@ethersproject/providers";
import Safe, {EthersAdapter} from "@safe-global/protocol-kit";
import {SafeTransaction} from "@safe-global/safe-core-sdk-types";
import {ethers} from "ethers";

export async function approveTransaction(approver: JsonRpcSigner, safe: Safe, safeTransaction: SafeTransaction) {
    const ethAdapterSigner: EthersAdapter = new EthersAdapter({
        ethers,
        signerOrProvider: approver
    })

    const safeSdkApprover: Safe = await safe.connect({ethAdapter: ethAdapterSigner})
    const txHash: string = await safeSdkApprover.getTransactionHash(safeTransaction);

    return await safeSdkApprover.approveTransactionHash(txHash)
}