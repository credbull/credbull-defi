// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract ERC1155MintableBurnable is ERC1155, IERC5679Ext1155 {
    constructor() ERC1155("") { }

    function safeMint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) public override {
        _mint(_to, _id, _amount, _data); // "safe" as parent ERC1155 _mint(_update) calls _doSafeTransferAcceptanceCheck
    }

    function safeMintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data)
        public
    {
        _mintBatch(_to, _ids, _amounts, _data); // "safe" as parent ERC1155 _mint(_update) calls _doSafeTransferAcceptanceCheck
    }

    function burn(address _from, uint256 _id, uint256 _amount, bytes[] calldata /* _data */ ) public override {
        _burn(_from, _id, _amount);
    }

    function burnBatch(address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata /* _data */ )
        public
    {
        _burnBatch(_from, _ids, _amounts);
    }

    // Add ERC165 support for IERC5679Ext1155
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IERC5679Ext1155).interfaceId || ERC1155.supportsInterface(interfaceId);
    }
}
