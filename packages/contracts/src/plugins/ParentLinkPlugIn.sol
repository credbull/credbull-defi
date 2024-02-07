//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract ParentLinkPlugIn {
    error CredbullVault__CallerIsNotParent();

    address public parentLink;

    bool public checkParentLink;

    constructor() {
        checkParentLink = true;
    }

    function _checkParentLink(address caller) internal view virtual {
        if (checkParentLink && caller != parentLink) {
            revert CredbullVault__CallerIsNotParent();
        }
    }

    function _toggleParentLinkCheck(bool status) internal virtual {
        checkParentLink = status;
    }

    function setParentLink(address _parentLink) public {
        parentLink = _parentLink;
    }
}
