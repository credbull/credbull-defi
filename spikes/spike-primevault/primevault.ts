require('dotenv').config();  // Load environment variables

const Web3 = require('web3').default;
const web3 = new Web3('https://mainnet.infura.io/v3/1');
const { APIClient } = require("@primevault/js-api-sdk");

const apiUrl = "https://app.primevault.com";
const apiKey = process.env.API_USER_API_KEY; // api users key, from https://app.primevault.com/app/users
const privateKey = process.env.API_USER_KEYPAIR_PRIVATE_KEY; // private key from keypair used to create the api user
const vaultId = process.env.VAULT_ID; // vault for the txn.  (e.g. from vault URL https://app.primevault.com/app/vault-details/6ae4fcee-d78d-43c5-baf1-10242defaa61 )

const apiClient = new APIClient(apiKey, apiUrl, privateKey);

const EIP20_ABI = [
  {
    "constant": false,
    "inputs": [
      {"name": "_spender", "type": "address"},
      {"name": "_value", "type": "uint256"},
    ],
    "name": "approve",
    "outputs": [{"name": "", "type": "bool"}],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function",
  },
]

const contractAddress = Web3.utils.toChecksumAddress('0x53e0bca35ec356bd5dddfebbd1fc0fd03fabad39') // contract address to invoke, e.g. chainLink token address
const spender = Web3.utils.toChecksumAddress('0x1cfe8c41Aa2B04257615b94B236C5c7C03B5EfE0')  // from address

const getMessageData = () => {
  const amount = 1000000000000000000
  const tokenContract = new web3.eth.Contract(EIP20_ABI, contractAddress);
  return tokenContract.methods.approve(spender, amount).encodeABI();
}

const createTransaction = async () => {
  const messageHex = await getMessageData();
  console.log(`Message hex: ${messageHex}`);
  const response = await apiClient.createContractCallTransaction(
    vaultId,
    "POLYGON",
    messageHex,
    contractAddress,
  );
  console.log(response);
}

createTransaction().then(() => {
  console.log('Transaction created');
})


