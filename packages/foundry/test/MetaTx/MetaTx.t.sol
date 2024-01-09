// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, console2 } from "forge-std/Test.sol";
import {MetaVault} from "../../contracts/MetaTx/MetaVault.sol";
import {MockStablecoin} from "../mocks/MockStablecoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EIP712Base} from "../../contracts/MetaTx/EIP712Base.sol";
import {MockERC20Permit} from "../mocks/MockERC20Permit.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract MetaTxTest is Test {
    
    MetaVault meta;
    MockStablecoin usdc;
    MockERC20Permit usdt;
    address sender = vm.addr(123);
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));
     bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));
     bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");


    function setUp() public {
        usdc = new MockStablecoin(type(uint128).max);
        usdt = new MockERC20Permit();
        meta = new MetaVault("Test", "t", IERC20(usdt));

        usdc.mint(sender, 1000 ether);
        usdt.mint(sender, 1000 ether);
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() internal view returns(bytes32) {
        return keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes("Cred")),
            keccak256(bytes("1")),
            address(meta),
            bytes32(getChainID())
        ));
    }


    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }

    function testMetaTransaction() public {
        uint256 amount = 100 ether;

        bytes memory functionSignature = abi.encodeCall(IERC4626.deposit, (amount, sender));

        bytes32 hashedMessage = toTypedMessageHash(
            keccak256(
                abi.encode(
                META_TRANSACTION_TYPEHASH,
                meta.getNonce(sender),
                sender,
                keccak256(functionSignature)
            )
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(123, hashedMessage);

        vm.prank(sender);
        usdt.approve(address(meta), amount);

        meta.executeMetaTransaction(address(meta), address(sender), functionSignature, v, r, s);
        assertEq(usdt.balanceOf(sender), 900 ether);
        assertEq(meta.balanceOf(sender), amount);
    }

    function testDepsitWithPermitAsMetaTransaction() public {
        uint256 amount = 100 ether;
        uint256 deadline = block.timestamp + 7 days;

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, sender, address(meta), amount, usdt.nonces(sender) , deadline));

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                usdt.DOMAIN_SEPARATOR(),
                structHash
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(123, hash);

        bytes memory functionSignature = abi.encodeCall(MetaVault.depositWithPermit, (sender, sender, amount, deadline, v, r, s));

        bytes32 hashedMessage = toTypedMessageHash(
            keccak256(
                abi.encode(
                META_TRANSACTION_TYPEHASH,
                meta.getNonce(sender),
                sender,
                keccak256(functionSignature)
            )
        ));

        (uint8 vM, bytes32 rM, bytes32 sM) = vm.sign(123, hashedMessage);

        meta.executeMetaTransaction(address(meta), address(sender), functionSignature, vM, rM, sM);
        assertEq(usdt.balanceOf(sender), 900 ether);
        assertEq(meta.balanceOf(sender), amount);
    }
}