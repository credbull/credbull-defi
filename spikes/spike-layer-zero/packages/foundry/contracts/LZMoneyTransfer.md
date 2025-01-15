# LZMoneyTransfer Smart Contract Documentation

## Overview

The `LZMoneyTransfer` contract facilitates cross-chain Ether transfers using LayerZero, a blockchain interoperability protocol. The contract is designed to send Ether from one chain to another, leveraging LayerZero's messaging framework.

## Prerequisites

- **LayerZero Protocol**: A trustless, secure communication layer enabling interoperability between blockchains. It ensures reliable cross-chain message delivery.

## Contract Details

### Inherited Contracts

- **NonblockingLzApp**: Provides the implementation for LayerZero messaging with guaranteed nonblocking functionality.

### State Variables

- **destChainId**: The LayerZero chain ID of the destination chain.
- **payload**: Encoded data to be sent cross-chain.
- **deployer**: The contract deployer's address, set during contract deployment.
- **contractAddress**: The address of the deployed contract.
- **endpoint**: Instance of `ILayerZeroEndpoint`, representing the LayerZero messaging endpoint.

### Constructor

```solidity
constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) Ownable(msg.sender) {
    deployer = payable(msg.sender);
    endpoint = ILayerZeroEndpoint(_lzEndpoint);

    // If Source == ArbitrubSepolia, then Destination Chain = OptimismSepolia
    if (_lzEndpoint == 0x6098e96a28E02f27B1e6BD381f870F1C8Bd169d3) destChainId = 10232;

    // If Source == OptimismSepolia, then Destination Chain = ArbitrubSepolia
    if (_lzEndpoint == 0x55370E0fBB5f5b8dAeD978BA1c075a499eB107B8) destChainId = 10231;
}
```

- **Parameters**:

  - `_lzEndpoint`: Address of the LayerZero endpoint for the source chain.

- **Functionality**:
  - Sets the deployer's address.
  - Initializes the LayerZero endpoint instance.
  - Determines the destination chain ID based on the provided endpoint address.

### Functions

#### sendTokens

```solidity
function sendTokens(address _toAddress) external payable {
    require(msg.value >= 0.01 ether, "Please send at least 0.01 Eth");
    uint value = msg.value;

    bytes memory trustedRemote = trustedRemoteLookup[destChainId];
    require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
    _checkPayloadSize(destChainId, payload.length);

    payload = abi.encode(_toAddress, value);

    endpoint.send{value: value}(destChainId, trustedRemote, payload, payable(address(this)), address(0x0), bytes(""));
}
```

- **Parameters**:

  - `_toAddress`: Address of the recipient on the destination chain.

- **Functionality**:
  - Ensures the sender provides at least 0.01 ETH.
  - Encodes the recipient's address and the value in the payload.
  - Sends the payload to the destination chain via the LayerZero endpoint.

#### \_nonblockingLzReceive

```solidity
function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
) internal override {
    (address _toAddress , uint value) = abi.decode(_payload, (address, uint));
    address payable recipient = payable(_toAddress);
    recipient.transfer(value);
}
```

- **Parameters**:

  - `_srcChainId`: Chain ID of the source chain.
  - `_srcAddress`: Address of the sender on the source chain.
  - `_nonce`: Nonce for the message.
  - `_payload`: Encoded data sent from the source chain.

- **Functionality**:
  - Decodes the payload to extract the recipient address and value.
  - Transfers the value to the recipient.

#### receive

```solidity
receive() external payable {}
```

- **Functionality**:
  - Allows the contract to receive native cryptocurrency (e.g., ETH).

#### withdrawAll

```solidity
function withdrawAll() external onlyOwner {
    deployer.transfer(address(this).balance);
}
```

- **Functionality**:
  - Allows the contract owner to withdraw all ETH stored in the contract.

## Usage

### Sending Tokens

1. Ensure the destination chain is trusted by verifying `trustedRemoteLookup` for the destination chain ID.
2. Call `sendTokens` with the recipient's address and send at least 0.01 ETH as `msg.value`.

### Receiving Tokens

Tokens sent via `sendTokens` will be automatically forwarded to the recipient's address on the destination chain by the `_nonblockingLzReceive` function.

### Emergency Withdrawals

Use the `withdrawAll` function to recover all ETH stored in the contract in case of emergencies.

## Notes

- Ensure the LayerZero endpoints are configured correctly for both source and destination chains.
- Use the LayerZero documentation to fetch the appropriate chain IDs and endpoint addresses for your deployment environment.

## TypeScript Integration Example

```typescript
import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
  const ethereumSepoliaContractAddress = "<Ethereum_Sepolia_Contract_Address>";
  const optimismSepoliaContractAddress = "<Optimism_Sepolia_Contract_Address>";

  const ethereumSepoliaChainId = 10121;
  const optimismSepoliaChainId = 10132;

  const contractABI = [
    "function setTrustedRemote(uint16 _remoteChainId, bytes calldata _remoteAddress) external",
    "function sendTokens(address _toAddress) external payable",
    "function estimateFees(uint16 _dstChainId, address _sender, address _recipient, uint256 _amount, bool _payInZRO, bytes calldata _adapterParams) external view returns (uint256, uint256)"
  ];

  const sepoliaProvider = new ethers.providers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const sepoliaWallet = new ethers.Wallet(process.env.PRIVATE_KEY!, sepoliaProvider);

  const optimismProvider = new ethers.providers.JsonRpcProvider(process.env.OPTIMISM_RPC_URL);
  const optimismWallet = new ethers.Wallet(process.env.PRIVATE_KEY!, optimismProvider);

  const ethereumSepoliaContract = new ethers.Contract(ethereumSepoliaContractAddress, contractABI, sepoliaWallet);
  const optimismSepoliaContract = new ethers.Contract(optimismSepoliaContractAddress, contractABI, optimismWallet);

  const optimismTrustedRemote = ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [optimismSepoliaContractAddress]
  );
  console.log("Setting trusted remote on Ethereum Sepolia...");
  let tx = await ethereumSepoliaContract.setTrustedRemote(optimismSepoliaChainId, optimismTrustedRemote);
  console.log("Transaction hash:", tx.hash);
  await tx.wait();
  console.log("Trusted remote set on Ethereum Sepolia.");

  const ethereumTrustedRemote = ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [ethereumSepoliaContractAddress]
  );
  console.log("Setting trusted remote on Optimism Sepolia...");
  tx = await optimismSepoliaContract.setTrustedRemote(ethereumSepoliaChainId, ethereumTrustedRemote);
  console.log("Transaction hash:", tx.hash);
  await tx.wait();
  console.log("Trusted remote set on Optimism Sepolia.");

  const recipientAddress = "<Recipient_Address>";
  const amountToSend = ethers.utils.parseEther("0.01");
  const adapterParams = ethers.utils.defaultAbiCoder.encode(["uint16", "uint256"], [1, 200000]);

  console.log("Estimating LayerZero fees...");
  const [nativeFee] = await ethereumSepoliaContract.estimateFees(
    optimismSepoliaChainId,
    sepoliaWallet.address,
    recipientAddress,
    amountToSend,
    false,
    adapterParams
  );
  console.log("Estimated LayerZero fee (in wei):", nativeFee.toString());

  console.log("Sending tokens...");
  tx = await ethereumSepoliaContract.sendTokens(recipientAddress, {
    value: amountToSend.add(nativeFee),
    gasLimit: 300000
  });
  console.log("Transaction hash:", tx.hash);
  await tx.wait();
  console.log("Tokens sent successfully.");
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
```