// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155Pausable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Test } from "forge-std/Test.sol";

contract SimpleMultiToken is ERC1155, Ownable, ERC1155Pausable, ERC1155Burnable, ERC1155Supply {
    uint256 public constant FOO = 1;
    uint256 public constant BAR = 2;
    uint256 public constant C = 3;
    uint256 public constant D = 4;
    uint256 public constant E = 5;

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {
        _mint(initialOwner, FOO, 1000 * 10 ** 18, "");
        _mint(initialOwner, BAR, 500 * 10 ** 18, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function mintFoo(address account, uint256 amount) public onlyOwner {
        _mint(account, FOO, amount, "");
    }

    function mintBar(address account, uint256 amount) public onlyOwner {
        _mint(account, BAR, amount, "");
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}

contract SimpleMultiTokenTest is Test {
    SimpleMultiToken private token;
    address private owner;
    address private addr1;

    function setUp() public {
        // owner = address(this);
        owner = msg.sender;
        addr1 = address(0x1);

        token = new SimpleMultiToken(owner);
    }

    function test__SimpleERC1155TokenTest_testInitialSupply() public {
        uint256 fooBalance = token.balanceOf(owner, token.FOO());
        uint256 barBalance = token.balanceOf(owner, token.BAR());

        assertEq(fooBalance, 1000 * 10 ** 18);
        assertEq(barBalance, 500 * 10 ** 18);
    }

    function test__SimpleERC1155TokenTest_testMintFoo() public {
        uint256 amount = 100 * 10 ** 18;
        vm.prank(owner);
        token.mintFoo(addr1, amount);

        uint256 fooBalance = token.balanceOf(addr1, token.FOO());
        assertEq(fooBalance, amount);
    }

    function test__SimpleERC1155TokenTest_testMintBar() public {
        uint256 amount = 50 * 10 ** 18;
        vm.prank(owner);
        token.mintBar(addr1, amount);

        uint256 barBalance = token.balanceOf(addr1, token.BAR());
        assertEq(barBalance, amount);
    }
}
