// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

pragma solidity ^0.8.13;

contract CredbullLedger {
    address public immutable owner;
    string public assetId;

    struct Order {
        address investorAddress;

        uint orderQuanity;
        address orderCurrency; // stablecoin contract address

        uint timestamp;
    }

    constructor(string memory _assetId) {
        owner = msg.sender;
        assetId = _assetId;
    }

}

contract CredbullLedgerTest is Test {
    string TEST_FUND_A = "Fund A";

    CredbullLedger credbullLedger;

    function setUp() public {
        credbullLedger = new CredbullLedger(TEST_FUND_A);
    }

    function testConstructor() public {
        assertEq(credbullLedger.owner(), address(this));
        assertEq(credbullLedger.assetId(), TEST_FUND_A);
    }
}
