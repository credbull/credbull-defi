
import {
    CredbullFixedYieldVault,
    CredbullFixedYieldVaultFactory,
    CredbullFixedYieldVaultFactory__factory,
    CredbullFixedYieldVault__factory,
    CredbullUpsideVaultFactory,
    CredbullUpsideVaultFactory__factory,
} from '@credbull/contracts';

import { utils, BigNumber} from 'ethers' ;
import dotenv from 'dotenv' ;

import { APIClient, CreateContractCallTransactionRequest } from '@primevault/js-api-sdk' ;
dotenv.config();

const apiUrl = "https://app.primevault.com";
const apiKey = process.env.API_USER_API_KEY || ""; // api users key, from https://app.primevault.com/app/users
const privateKey = process.env.API_USER_KEYPAIR_PRIVATE_KEY; // private key from keypair used to create the api user
const vaultId = process.env.VAULT_ID || ""; // vault for the txn.  (e.g. from vault URL https://app.primevault.com/app/vault-details/6ae4fcee-d78d-43c5-baf1-10242defaa61 )

const apiClient = new APIClient(apiKey, apiUrl, privateKey);


const getMessageData = (method: string, params:any[] = []) => {
  const vaultInterface = new utils.Interface(CredbullFixedYieldVault__factory.abi);
  return vaultInterface.encodeFunctionData(method, params);
}

const createTransaction = async (contractAddress: string, method: string, params:any[] = []) => {
  const messageHex = getMessageData(method, params);
  console.log(`Message hex: ${messageHex}`);
  const request: CreateContractCallTransactionRequest = {
    vaultId: vaultId,
    chain: 'POLYGON',
    messageHex: messageHex,
    toAddress: contractAddress
  }
  const response = await apiClient.createContractCallTransaction(
    request
  );
  console.log(response);
}


export async function main(opts: any[], args: any) {
  //TODO: Fix this
  const params = args.params ? args.params.split(","): [];
  await createTransaction(args.contract, args.method, params);
}