//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployWrappedERC20 } from "@script/DeployWrappedERC20.s.sol";
import { ERC20Wrapper } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { WrappedERC20 } from "@credbull/token/ERC20/WrappedERC20.sol";

contract WrappedERC20Test is Test {
    IERC20 private _underlyingToken;
    uint256 private _underlyingTokenScale;

    DeployWrappedERC20 private _deployer;
    ERC20Wrapper private _wrapperToken;

    WrappedERC20.Params private _params;

    address private _alice = makeAddr("alice");
    address private _bob = makeAddr("bob");

    function setUp() public {
        address owner = makeAddr("tokenOwner");

        SimpleToken simpleToken = new SimpleToken(owner, (type(uint256).max));
        _underlyingToken = simpleToken;
        _underlyingTokenScale = 10 ** simpleToken.decimals();

        _params = WrappedERC20.Params({
            owner: owner,
            name: "WrapperToken-V1",
            symbol: "wT-V1",
            underlyingToken: _underlyingToken
        });

        _deployer = new DeployWrappedERC20(_underlyingToken);
        _wrapperToken = _deployer.run(_params);

        assertEq(
            _underlyingToken.totalSupply(),
            _underlyingToken.balanceOf(_params.owner),
            "owner should start with all tokens"
        );
        vm.prank(_params.owner);
        _underlyingToken.transfer(_alice, 1_000_000 * _underlyingTokenScale);
    }

    function test__WrappedERC20__Deploy() public {
        uint256 depositAmount = 250_000 * _underlyingTokenScale;
        uint256 prevUnderlyingBal = _underlyingToken.balanceOf(_alice);

        assertNotEq(address(0), address(_wrapperToken));
        assertEq(_params.name, _wrapperToken.name());
        assertEq(_params.symbol, _wrapperToken.symbol());

        assertEq(0, _wrapperToken.totalSupply(), "wrapper total supply should start at zero");
        assertEq(0, _wrapperToken.balanceOf(_alice), "user wrapper balance should start at zero");

        // grant allowance
        vm.prank(_alice);
        _underlyingToken.approve(address(_wrapperToken), depositAmount);

        // now deposit
        vm.prank(_alice);
        _wrapperToken.depositFor(_alice, depositAmount);

        assertEq(
            depositAmount, _wrapperToken.totalSupply(), "wrapper total supply should be deposit tokens after deposit"
        );
        assertEq(depositAmount, _wrapperToken.balanceOf(_alice), "user should have deposit tokens after deposit");
        assertEq(
            prevUnderlyingBal - depositAmount,
            _underlyingToken.balanceOf(_alice),
            "alice should have deposit fewer underlying after deposit"
        );
    }
}
