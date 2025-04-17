//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { DeployWrappedERC20 } from "@script/DeployWrappedERC20.s.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { WrappedERC20, Ownable } from "@credbull/token/ERC20/WrappedERC20.sol";

contract WrappedERC20Test is Test {
    IERC20Metadata private _underlyingToken;
    uint256 private _underlyingTokenScale;

    DeployWrappedERC20 private _deployer;

    WrappedERC20 private _wrappedToken;
    WrappedERC20.Params private _params;

    address private _alice = makeAddr("alice");
    address private _bob = makeAddr("bob");

    function setUp() public {
        address owner = makeAddr("tokenOwner");

        SimpleToken simpleToken = new SimpleToken(owner, (type(uint256).max));
        _underlyingToken = simpleToken;
        _underlyingTokenScale = 10 ** simpleToken.decimals();

        _deployer = new DeployWrappedERC20();
        _deployer.setPostfix("-TEST_2025");
        _params = _deployer.createParams(owner, _underlyingToken);
        _wrappedToken = _deployer.run(_params);

        assertEq(
            _underlyingToken.totalSupply(),
            _underlyingToken.balanceOf(_params.owner),
            "owner should start with all tokens"
        );
        vm.prank(_params.owner);
        _underlyingToken.transfer(_alice, 1_000_000 * _underlyingTokenScale);
    }

    function test__WrappedERC20__Deploy() public view {
        assertNotEq(address(0), address(_wrappedToken));
        assertEq(address(_underlyingToken), address(_wrappedToken.underlying()), "underlying incorrect");
        assertEq(_params.owner, Ownable(address(_wrappedToken)).owner(), "owner incorrect");
        assertEq(_params.name, _wrappedToken.name(), "name incorrect");
        assertEq(_params.symbol, _wrappedToken.symbol(), "symbol incorrect");
    }

    function test__WrappedERC20__DepositAndRedeem() public {
        uint256 depositAmount = 250_000 * _underlyingTokenScale;
        uint256 prevUnderlyingBal = _underlyingToken.balanceOf(_alice);

        assertEq(0, _wrappedToken.totalSupply(), "wrapper total supply should start at zero");
        assertEq(0, _wrappedToken.balanceOf(_alice), "alice wrapper balance should start at zero");

        // grant allowance
        vm.prank(_alice);
        _underlyingToken.approve(address(_wrappedToken), depositAmount);

        // deposit
        vm.prank(_alice);
        _wrappedToken.depositFor(_alice, depositAmount);

        assertEq(
            depositAmount, _wrappedToken.totalSupply(), "wrapper total supply should be deposit tokens after deposit"
        );
        assertEq(depositAmount, _wrappedToken.balanceOf(_alice), "alice should have deposit tokens after deposit");
        assertEq(
            prevUnderlyingBal - depositAmount,
            _underlyingToken.balanceOf(_alice),
            "alice should have deposit fewer underlying after deposit"
        );

        // withdrawTo
        address recipient = makeAddr("someRecipient");

        vm.prank(_alice);
        _wrappedToken.withdrawTo(recipient, depositAmount);

        assertEq(depositAmount, _underlyingToken.balanceOf(recipient), "recipient should have full deposit amount");
        assertEq(_wrappedToken.balanceOf(_alice), 0, "alice should have zero wrapped tokens after withdrawal");
        assertEq(0, _wrappedToken.totalSupply(), "wrapper supply should be zero after withdrawal");
    }

    function test__WrappedERC20__RecoverTransferredTokens() public {
        uint256 depositAmount = 75_000 * _underlyingTokenScale;

        // user transfers tokens (likely a mistake - should call depositFor instead)
        vm.prank(_alice);
        _underlyingToken.transfer(address(_wrappedToken), depositAmount);

        assertEq(0, _wrappedToken.balanceOf(_alice), "alice transferred tokens, receives zero wrapped tokens");

        vm.expectEmit(true, false, false, true); // match indexed `account` and data `amount`
        emit WrappedERC20.WrappedERC20__TokensRecovered(_alice, depositAmount); // expected event shape

        // owner can recover for the user
        vm.prank(_params.owner);
        _wrappedToken.recover(_alice);

        assertEq(depositAmount, _wrappedToken.balanceOf(_alice), "alice should have deposit after recover");
    }

    function test__WrappedERC20__RecoverRevertsForNonOwner() public {
        uint256 depositAmount = 50_000 * _underlyingTokenScale;

        vm.prank(_alice);
        _underlyingToken.transfer(address(_wrappedToken), depositAmount);

        vm.prank(_bob); // not owner
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _bob));
        _wrappedToken.recover(_bob);
    }
}
