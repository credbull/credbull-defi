//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "@layerzerolabs/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LZMoneyTransfer is NonblockingLzApp {
    address payable public deployer;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) Ownable(msg.sender) {
        deployer = payable(msg.sender);
    }

    // Estimate fees for sending ETH cross-chain
    // function estimateFee(
    //     uint16 _dstChainId,
    //     bool _useZro,
    //     bytes calldata _adapterParams
    // ) public view returns (uint nativeFee, uint zroFee) {
    //     // Estimate fees for sending an ETH payload
    //     bytes memory payload = abi.encode(msg.sender, msg.value);
    //     return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    // }

    // Send ETH cross-chain
    function sendETH(uint16 _dstChainId) external payable {
        require(msg.value > 0, "Must send some ETH");

        // Prepare payload with recipient's address and amount of ETH to send
        bytes memory payload = abi.encode(msg.sender, msg.value);

        // Send ETH cross-chain using LayerZero
        _lzSend(_dstChainId, payload, payable(msg.sender), address(0x0), bytes(""), msg.value);
    }

    // Receiving function on the destination chain
    function _nonblockingLzReceive(
        uint16, // _srcChainId
        bytes memory, // _srcAddress
        uint64, // _nonce
        bytes memory _payload // _payload
    ) internal override {
        // Decode the payload to get recipient address and amount
        (address payable recipient, uint amount) = abi.decode(_payload, (address, uint));

        // Transfer the received ETH to the recipient
        require(address(this).balance >= amount, "Insufficient balance");
        recipient.transfer(amount);
    }

    // Allow contract to receive ETH
    receive() external payable {}

    // Emergency withdrawal by the owner
    function withdrawAll() external onlyOwner {
        deployer.transfer(address(this).balance);
    }
}