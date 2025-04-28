// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1155Hashable } from "@credbull/token/ERC1155/ERC1155Hashable.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { DeployERC1155Hashable } from "@script/token/ERC1155/DeployERC1155Hashable.s.sol";

import { Test } from "forge-std/Test.sol";

contract ERC1155HashableTest is Test {
    struct TokenData {
        string checksum;
        string uri;
    }

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

        assertEq(tokenId, 1, "token ID should be 1 after first mint");
        assertEq(_hashableToken.balanceOf(address(_hashableToken), tokenId), 1, "contract should hold the minted token");
        assertEq(_hashableToken.checksums(tokenId), hashValue, "stored hash should match input");
        assertEq(_hashableToken.uris(tokenId), uriValue, "stored uri should match input");
        assertEq(_hashableToken.currentChecksum(), hashValue, "currentChecksum() should return latest hash");
        assertEq(_hashableToken.currentURI(), uriValue, "currentURI() should return latest uri");
        assertEq(_hashableToken.uri(tokenId), uriValue, "uri(tokenId) should match stored uri");
    }

    function test__ERC1155Hashable__MultipleMints() public {
        TokenData[3] memory tokens = [
            TokenData("checksum1", "ipfs://uri1"),
            TokenData("checksum2", "ipfs://uri2"),
            TokenData("checksum3", "ipfs://uri3")
        ];

        vm.startPrank(_minter);
        for (uint256 i = 0; i < tokens.length; ++i) {
            _hashableToken.mint(tokens[i].checksum, tokens[i].uri);
        }
        vm.stopPrank();

        assertEq(_hashableToken.currentId(), 3, "should track last minted token id");

        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 tokenId = i + 1; // token IDs start from 1 after first mint

            assertEq(_hashableToken.checksums(tokenId), tokens[i].checksum, "checksum should match for token");
            assertEq(_hashableToken.uris(tokenId), tokens[i].uri, "uri should match for token");
            assertEq(_hashableToken.uri(tokenId), tokens[i].uri, "ERC1155 uri(tokenId) should match stored uri");
        }

        assertEq(_hashableToken.currentChecksum(), tokens[2].checksum, "currentChecksum() should match latest checksum");
        assertEq(_hashableToken.currentURI(), tokens[2].uri, "currentURI() should match latest uri");
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
