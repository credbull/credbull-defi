// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1155Hashable } from "@credbull/token/ERC1155/ERC1155Hashable.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { DeployERC1155Hashable } from "@script/token/ERC1155/DeployERC1155Hashable.s.sol";

import { Test } from "forge-std/Test.sol";

contract ERC1155HashableTest is Test {
    ERC1155Hashable private _hashableToken;
    DeployERC1155Hashable private _deployer;

    address private _owner = makeAddr("owner");
    address private _minter = makeAddr("minter");

    function setUp() public {
        _deployer = new DeployERC1155Hashable();

        _hashableToken = _deployer.run(_owner, _minter);
        vm.stopPrank();
    }

    function test__ERC1155Hashable__InitialState() public {
        assertEq(_hashableToken.currentId(), 0, "initial token id should be zero");

        assertTrue(_hashableToken.hasRole(_hashableToken.DEFAULT_ADMIN_ROLE(), _owner), "owner should have owner role");
        assertTrue(_hashableToken.hasRole(_hashableToken.MINTER_ROLE(), _minter), "minter should have minter role");
    }

    function test__ERC1155Hashable__MintWithHash() public {
        string memory hashValue = "QmHash123";

        vm.expectEmit(true, false, false, true); // match indexed `account` and data `amount`
        emit ERC1155Hashable.ERC1155Hashable__MintedWithHash(1, address(_hashableToken), hashValue); // expected event shape

        vm.prank(_minter);
        _hashableToken.mintWithHash(hashValue);

        uint256 tokenId = _hashableToken.currentId();

        assertEq(tokenId, 1, "token ID should be 1 after first mint");
        assertEq(_hashableToken.balanceOf(address(_hashableToken), tokenId), 1, "contract should hold the minted token");
        assertEq(_hashableToken.hashes(tokenId), hashValue, "stored hash should match input");
        assertEq(_hashableToken.currentHash(), hashValue, "currentHash() should return latest stored hash");
    }

    function test__ERC1155Hashable__MultipleMints() public {
        vm.startPrank(_minter);
        _hashableToken.mintWithHash("hash1");
        _hashableToken.mintWithHash("hash2");
        _hashableToken.mintWithHash("hash3");
        vm.stopPrank();

        assertEq(_hashableToken.currentId(), 3, "should track last minted token id");
        assertEq(_hashableToken.hashes(2), "hash2", "hash for token ID 2 should match");
        assertEq(_hashableToken.currentHash(), "hash3", "currentHash() should return the latest hash");
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
}
