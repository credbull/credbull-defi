# StargateUSDCBridge Smart Contract Documentation

## Overview

The `StargateUSDCBridge` contract facilitates cross-chain transfers of USDC tokens using the Stargate protocol. It allows users to transfer USDC from the current chain to a specified destination chain seamlessly.

## Contract Details

### Interfaces

- **IStargateRouter**: Defines the primary functions to interact with the Stargate protocol, including `swap`, `addLiquidity`, and others.

- **IERC20**: Standard interface for ERC20 tokens, providing functions like `transfer`, `approve`, and `transferFrom`.

### State Variables

- **stargateRouter**: An instance of the `IStargateRouter` interface, representing the Stargate router contract used for cross-chain operations.

- **usdcToken**: An instance of the `IERC20` interface, representing the USDC token contract.

### Constructor

```solidity
constructor(address _stargateRouter, address _usdcToken) Ownable(msg.sender) {
    stargateRouter = IStargateRouter(_stargateRouter);
    usdcToken = IERC20(_usdcToken);
}
```

- **Parameters**:

  - `_stargateRouter`: The address of the deployed Stargate router contract.
  - `_usdcToken`: The address of the USDC token contract.

- **Functionality**: Initializes the contract by setting the Stargate router and USDC token addresses. It also sets the contract deployer as the owner.

### Functions

#### transferUSDC

```solidity
function transferUSDC(
    uint16 _dstChainId,
    uint256 _srcPoolId,
    uint256 _dstPoolId,
    address _recipient,
    uint256 _amount,
    uint256 _minAmountLD,
    IStargateRouter.lzTxObj memory _lzTxParams,
    bytes calldata _adapterParams
) external payable {
    // require(usdcToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
    // usdcToken.approve(address(stargateRouter), _amount);

    stargateRouter.swap{value: msg.value}(
        _dstChainId,
        _srcPoolId,
        _dstPoolId,
        payable(msg.sender),
        _amount,
        _minAmountLD,
        _lzTxParams,
        abi.encodePacked(_recipient),
        _adapterParams
    );
}
```

- **Parameters**:

  - `_dstChainId`: The LayerZero chain ID of the destination chain.
  - `_srcPoolId`: The source pool ID in the Stargate protocol.
  - `_dstPoolId`: The destination pool ID in the Stargate protocol.
  - `_recipient`: The address of the recipient on the destination chain.
  - `_amount`: The amount of USDC to transfer.
  - `_minAmountLD`: The minimum amount of liquidity token (LD) to receive on the destination chain.
  - `_lzTxParams`: A struct containing LayerZero transaction parameters:
    - `dstGasForCall`: Additional gas to be provided on the destination chain for contract execution.
    - `dstNativeAmount`: Amount of native token to be sent to the destination.
    - `dstNativeAddr`: Address to receive the native token on the destination chain.
  - `_adapterParams`: Additional parameters for the adapter, encoded as bytes.

- **Functionality**:
  - **Token Transfer**: Transfers the specified amount of USDC from the sender to the contract.
  - **Approval**: Approves the Stargate router to spend the USDC tokens.
  - **Swap Execution**: Calls the `swap` function on the Stargate router to initiate the cross-chain transfer.

**Note**: The `transferFrom` and `approve` calls are commented out. Ensure they are uncommented and the sender has approved the contract to spend USDC on their behalf before calling this function.

#### emergencyWithdraw

```solidity
function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
    IERC20(_token).transfer(owner(), _amount);
}
```

- **Parameters**:

  - `_token`: The address of the token to withdraw.
  - `_amount`: The amount of tokens to withdraw.

- **Functionality**: Allows the contract owner to withdraw a specified amount of tokens from the contract. This is useful in emergency situations to recover funds.

#### receive

```solidity
receive() external payable {}
```

- **Functionality**: Enables the contract to receive native cryptocurrency (e.g., ETH) directly. This is necessary to pay for cross-chain message fees required by the Stargate protocol.

## Usage

### Approval

Before calling `transferUSDC`, the user must approve the `StargateUSDCBridge` contract to spend their USDC tokens. This can be done by calling the `approve` function on the USDC token contract with the `StargateUSDCBridge` contract address and the amount to be transferred.

### Transfer

Call the `transferUSDC` function with the appropriate parameters to initiate a cross-chain transfer. Ensure that the `msg.value` sent with the transaction covers the LayerZero fees for the operation.
