// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { InCredbullVaultParams } from "../script/InCredbullVaultParams.s.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract InCredbullVaultParamsTest is Test {
    InCredbullVaultParams private icvParams;

    address private owner = makeAddr("owner");
    address private operator = makeAddr("operator");
    address private custodian = makeAddr("custodian");
    IERC20 private asset = IERC20(makeAddr("USDC"));

    uint256 private opensAt;

    function setUp() public {
        icvParams = new InCredbullVaultParams();

        opensAt = block.timestamp;
    }

    function test__InCredbullVaultParamsTest__testVaultParams() public view {
        string memory vault8APYSymbol = "vault8APY";
        ICredbull.VaultParams memory vault8APY =
            icvParams.create8APYParams(vault8APYSymbol, asset, owner, operator, custodian, opensAt);
        assertEq(vault8APYSymbol, vault8APY.shareSymbol, "wrong symbol");
        assertEq(4, vault8APY.promisedYield, "wrong APY");
        assertVaultParams(vault8APY, icvParams.HALF_YEAR());

        string memory vault10APYSymbol = "vault10APY";
        ICredbull.VaultParams memory vault10APY =
            icvParams.create10APYParams(vault10APYSymbol, asset, owner, operator, custodian, opensAt);
        assertEq(vault10APYSymbol, vault10APY.shareSymbol, "wrong symbol");
        assertEq(10, vault10APY.promisedYield, "wrong APY");
        assertVaultParams(vault10APY, icvParams.ONE_YEAR());
    }

    function assertVaultParams(ICredbull.VaultParams memory vaultParams, uint256 redeomptionOffset) public view {
        assertEq(address(asset), address(vaultParams.asset), "wrong asset");

        assertEq(owner, vaultParams.owner, "wrong owner");
        assertEq(operator, vaultParams.operator, "wrong operator");
        assertEq(custodian, vaultParams.custodian, "wrong custodian");

        uint256 closesAt = opensAt + 2 weeks;

        uint256 redemptionOpensAt = opensAt + redeomptionOffset;
        uint256 redemptionClosesAt = redemptionOpensAt + 2 weeks;

        assertEq(opensAt, vaultParams.depositOpensAt);
        assertEq(closesAt, vaultParams.depositClosesAt);
        assertEq(redemptionOpensAt, vaultParams.redemptionOpensAt);
        assertEq(redemptionClosesAt, vaultParams.redemptionClosesAt);
    }
}
