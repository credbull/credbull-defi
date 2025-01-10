//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "@layerzerolabs/lzApp/NonblockingLzApp.sol";

contract LZMoneyTransfer is NonblockingLzApp {
    uint16 public destChainId;
    bytes payload;
    address payable deployer;
    address payable contractAddress = payable(address(this));

    ILayerZeroEndpoint public immutable endpoint;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) Ownable(msg.sender) {
        deployer = payable(msg.sender);
        endpoint = ILayerZeroEndpoint(_lzEndpoint);

        // If Source == ArbitrubSepolia, then Destination Chain = OptimismSepolia
        if (_lzEndpoint == 0x6098e96a28E02f27B1e6BD381f870F1C8Bd169d3) destChainId = 10232;

        // If Source == OptimismSepolia, then Destination Chain = ArbitrubSepolia
        if (_lzEndpoint == 0x55370E0fBB5f5b8dAeD978BA1c075a499eB107B8) destChainId = 10231;
    }

    function sendTokens(address _toAddress) external payable {
        require(msg.value >= 0.01 ether, "Please send at least 0.01 Eth");
        uint value = msg.value;

        bytes memory trustedRemote = trustedRemoteLookup[destChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(destChainId, payload.length);

        payload = abi.encode(_toAddress, value);

        endpoint.send{value: value}(destChainId, trustedRemote, payload, payable(address(this)), address(0x0), bytes(""));
    }

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

    receive() external payable {}

    function withdrawAll() external onlyOwner {
        deployer.transfer(address(this).balance);
    }
}
