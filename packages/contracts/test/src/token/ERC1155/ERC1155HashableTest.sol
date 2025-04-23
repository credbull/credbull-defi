// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1155Hashable } from "@credbull/token/ERC1155/ERC1155Hashable.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { Test } from "forge-std/Test.sol";

contract ERC1155HashableTest is Test {
    ERC1155Hashable private _hashableToken;

    address private _admin = makeAddr("admin");
    address private _minter = makeAddr("minter");

    function setUp() public {
        vm.startPrank(_admin);
        _hashableToken = new ERC1155Hashable(_admin, _minter);
        vm.stopPrank();
    }

    function test__ERC1155Hashable__InitialState() public {
        assertEq(_hashableToken.currentId(), 0, "Initial token ID should be zero");
    }

    function test__ERC1155Hashable__MintWithHash() public {
        string memory hashValue = "QmHash123";

        vm.expectEmit(true, false, false, true); // match indexed `account` and data `amount`
        emit ERC1155Hashable.ERC1155Hashable__MintedWithHash(1, address(_hashableToken), hashValue); // expected event shape

        vm.prank(_minter);
        _hashableToken.mintWithHash(hashValue);

        uint256 tokenId = _hashableToken.currentId();

        assertEq(tokenId, 1, "Token ID should be 1 after first mint");
        assertEq(_hashableToken.balanceOf(address(_hashableToken), tokenId), 1, "Contract should hold the minted token");
        assertEq(_hashableToken.hashes(tokenId), hashValue, "Stored hash should match input");
        assertEq(_hashableToken.currentHash(), hashValue, "currentHash() should return latest stored hash");
    }

    function test__ERC1155Hashable__OnlyMinterCanMint() public {
        address randomWallet = makeAddr("randomWallet");

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, randomWallet, _hashableToken.MINTER_ROLE()
            )
        );
        vm.prank(randomWallet);
        _hashableToken.mintWithHash("someHash");
    }

    function test__ERC1155Hashable__MultipleMints() public {
        vm.startPrank(_minter);
        _hashableToken.mintWithHash("hash1");
        _hashableToken.mintWithHash("hash2");
        _hashableToken.mintWithHash("hash3");
        vm.stopPrank();

        assertEq(_hashableToken.currentId(), 3, "Should track last minted token ID");
        assertEq(_hashableToken.hashes(2), "hash2", "Hash for token ID 2 should match");
        assertEq(_hashableToken.currentHash(), "hash3", "currentHash() should return the latest hash");
    }
}
