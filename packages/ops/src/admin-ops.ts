import { APIClient, CreateContractCallTransactionRequest } from '@primevault/js-api-sdk';
import { CredbullFixedYieldVault__factory, CredbullFixedYieldVaultFactory__factory } from '@credbull/contracts';
import { utils } from 'ethers';
import { loadConfiguration } from './utils/config';


const config = loadConfiguration();

const apiClient = new APIClient(
    config.secret?.API_USER_API_KEY || "", 
    config.primevault.url, 
    config.secret?.API_USER_KEYPAIR_PRIVATE_KEY
);

const getMessageData = (factory: boolean, method: string, params:any[] = []) => {
    if (factory) {
        const vaultFactoryInterface = new utils.Interface(CredbullFixedYieldVaultFactory__factory.abi);
        return vaultFactoryInterface.encodeFunctionData(method, params);
    } else {
        const vaultInterface = new utils.Interface(CredbullFixedYieldVault__factory.abi);
        return vaultInterface.encodeFunctionData(method, params);
    }
}

const createTransaction = async (factory: boolean, contractAddress: string, method: string, params:any[] = []) => {
  const messageHex = getMessageData(factory, method, params);
  console.log(`Message hex: ${messageHex}`);
  const request: CreateContractCallTransactionRequest = {
    vaultId: config.secret?.VAULT_ID || "",
    chain: "ARBITRUM_TESTNET",
    messageHex: messageHex,
    toAddress: contractAddress
  }
  const response = await apiClient.createContractCallTransaction(
    request
  );
  console.log(response);
}


export async function main(
    scenarios: { factory: boolean },
    params: { contract: string, method: string, methodParams: string },
  ) {
    console.log(params.methodParams);
    const methodParams = params.methodParams.split('-');
    console.log(methodParams);
    await createTransaction(scenarios.factory, params.contract, params.method, methodParams);
}
