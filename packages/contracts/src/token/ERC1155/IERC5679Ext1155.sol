// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";

/*
 * ERC-5679: Token Minting and Burning
 * An extension for minting and [..] EIP-1155 tokens
 * Any contract complying with EIP-1155 when extended with this EIP, MUST implement the following interface:
 * @dev see https://eips.ethereum.org/EIPS/eip-5679
 */
interface IERC5679Ext1155 is IERC1155 {
    function safeMint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

    function safeMintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata data)
        external;

    function burn(address _from, uint256 _id, uint256 _amount, bytes[] calldata _data) external;

    function burnBatch(address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data)
        external;
}
