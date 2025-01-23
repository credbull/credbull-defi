// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { Test } from "forge-std/Test.sol";

abstract contract TestUtil is Test {
    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000010

    address public _owner = makeAddr("owner");
    address public _alice = makeAddr("alice");
    address public _bob = makeAddr("bob");
    address public _charlie = makeAddr("charlie");

    function _asSingletonArray(uint256 element) public pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = element;
    }

    /// @dev - create an erc20 for testing purposes
    function _createAsset(address owner) internal returns (IERC20Metadata asset) {
        return new SimpleUSDC(owner, 1_000_000 ether);
    }

    /// @dev - transfer from the owner of the IERC20 `token` to the `toAddress`
    function _transferFromTokenOwner(IERC20 token, address toAddress, uint256 amount) internal {
        // only works with Ownable token - need to override otherwise
        Ownable ownableToken = Ownable(address(token));

        _transferAndAssert(token, ownableToken.owner(), toAddress, amount);
    }

    /// @dev - transfer from the `fromAddress` to the `toAddress`
    function _transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
