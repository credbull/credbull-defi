// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

contract StargateUSDCBridge is Ownable {
    IStargateRouter public stargateRouter;
    IERC20 public usdcToken;

    constructor(address _stargateRouter, address _usdcToken) Ownable(msg.sender) {
        stargateRouter = IStargateRouter(_stargateRouter);
        usdcToken = IERC20(_usdcToken);
    }

    function transferUSDC(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _recipient,
        uint256 _amount,
        uint256 _minAmountLD,
        bytes calldata _adapterParams
    ) external payable {
        require(usdcToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        usdcToken.approve(address(stargateRouter), _amount);

        stargateRouter.swap{value: msg.value}(
            _dstChainId,         // Destination chain ID
            _srcPoolId,          // Source pool ID (USDC on Arbitrum Sepolia)
            _dstPoolId,          // Destination pool ID (USDC on Optimism Sepolia)
            msg.sender,          // Refund address
            _amount,             // Amount to transfer
            _minAmountLD,        // Minimum amount to receive on the destination chain
            abi.encodePacked(_recipient), // Encoded recipient address on destination chain
            _adapterParams       // Additional adapter parameters for gas settings
        );
    }

    // Emergency withdrawal
    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    receive() external payable {}
}
