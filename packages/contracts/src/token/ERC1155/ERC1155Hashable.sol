// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Hashable is ERC1155, ERC1155Holder, AccessControl {
    event ERC1155Hashable__MintedWithHash(uint256 indexed tokenId, address indexed to, string hash);

    uint256 public currentId = 0; // track the most recently minted token id

    mapping(uint256 => string) public hashes;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address defaultAdmin, address minter) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    function mintWithHash(string calldata hash) public onlyRole(MINTER_ROLE) {
        ++currentId; // pre-increment so currentId matches the new token being minted
        _mint(address(this), currentId, 1, "");
        hashes[currentId] = hash;

        emit ERC1155Hashable__MintedWithHash(currentId, address(this), hash);
    }

    function currentHash() external view returns (string memory) {
        return hashes[currentId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl, ERC1155Holder)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
