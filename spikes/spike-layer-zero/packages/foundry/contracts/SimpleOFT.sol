//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@layerzerolabs/token/oft/v2/OFTV2.sol";

contract SimpleOFT is OFTV2 {
    constructor(string memory _name, string memory _symbol, uint8 _sharedDecimals, address _lzEndpoint, uint256 _totalSupply) OFTV2(_name, _symbol, _sharedDecimals, _lzEndpoint) {
        _mint(msg.sender, _totalSupply);
    }
}
