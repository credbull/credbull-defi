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

    function test__ERC1155Hashable__Mint() public {
        string memory hashValue = "QmHash123";
        string memory uriValue = "ipfs://uri123";

        vm.expectEmit(true, false, false, true);
        emit ERC1155Hashable.ERC1155Hashable__Minted(1, address(_hashableToken), hashValue, uriValue);

        vm.prank(_minter);
        _hashableToken.mint(hashValue, uriValue);

        uint256 tokenId = _hashableToken.currentId();

        assertEq(tokenId, 1, "tokenId should be 1");
        assertEq(_hashableToken.balanceOf(address(_hashableToken), tokenId), 1, "contract should hold token");

        (string memory actualHash, string memory actualUri) = _hashableToken.metadata(tokenId);
        assertEq(actualHash, hashValue, "hash mismatch");
        assertEq(actualUri, uriValue, "uri mismatch");

        assertEq(_hashableToken.currentHash(), hashValue, "currentHash mismatch");
        assertEq(_hashableToken.currentURI(), uriValue, "currentURI mismatch");
        assertEq(_hashableToken.hash(tokenId), hashValue, "hash(tokenId) mismatch");
        assertEq(_hashableToken.uri(tokenId), uriValue, "uri(tokenId) mismatch");
    }

    function test__ERC1155Hashable__MultipleMints() public {
        ERC1155Hashable.Metadata[3] memory tokens = [
            ERC1155Hashable.Metadata("hash1", "ipfs://uri1"),
            ERC1155Hashable.Metadata("hash2", "ipfs://uri2"),
            ERC1155Hashable.Metadata("hash3", "ipfs://uri3")
        ];

        vm.startPrank(_minter);
        for (uint256 i = 0; i < tokens.length; ++i) {
            _hashableToken.mint(tokens[i].hash, tokens[i].uri);
        }
        vm.stopPrank();

        assertEq(_hashableToken.currentId(), 3, "currentId mismatch");

        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 tokenId = i + 1;

            (string memory actualHash, string memory actualUri) = _hashableToken.metadata(tokenId);
            assertEq(actualHash, tokens[i].hash, "hash mismatch at tokenId");
            assertEq(actualUri, tokens[i].uri, "uri mismatch at tokenId");

            assertEq(_hashableToken.hash(tokenId), tokens[i].hash, "hash(tokenId) mismatch");
            assertEq(_hashableToken.uri(tokenId), tokens[i].uri, "uri(tokenId) mismatch");
        }

        assertEq(_hashableToken.currentHash(), tokens[2].hash, "currentHash mismatch");
        assertEq(_hashableToken.currentURI(), tokens[2].uri, "currentURI mismatch");
    }

    function test__ERC1155Hashable__OnlyMinterCanMint() public {
        address randomWallet = makeAddr("randomWallet");

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, randomWallet, _hashableToken.MINTER_ROLE()
            )
        );
        vm.prank(randomWallet);
        _hashableToken.mint("someHash", "ipfs://someHash");
    }
}
