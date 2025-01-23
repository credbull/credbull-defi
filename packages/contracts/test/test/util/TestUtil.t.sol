// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { Test } from "forge-std/Test.sol";

abstract contract TestUtil is Test {
    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000010

    function _asSingletonArray(uint256 element) public pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = element;
    }

    // simple scenario with only one user
    function _createTestUsers(address account)
        internal
        virtual
        returns (TestParamSet.TestUsers memory depositUsers_, TestParamSet.TestUsers memory redeemUsers_)
    {
        // Convert the address to a string and then to bytes
        string memory accountStr = vm.toString(account);

        TestParamSet.TestUsers memory depositUsers = TestParamSet.TestUsers({
            tokenOwner: account, // owns tokens, can specify who can receive tokens
            tokenReceiver: makeAddr(string.concat("depositTokenReceiver-", accountStr)), // receiver of tokens from the tokenOwner
            tokenOperator: makeAddr(string.concat("depositTokenOperator-", accountStr)) // granted allowance by tokenOwner to act on their behalf
         });

        TestParamSet.TestUsers memory redeemUsers = TestParamSet.TestUsers({
            tokenOwner: depositUsers.tokenReceiver, // on deposit, the tokenReceiver receives (owns) the tokens
            tokenReceiver: account, // virtuous cycle, the account receives the returns in the end
            tokenOperator: makeAddr(string.concat("redeemTokenOperator-", accountStr)) // granted allowance by tokenOwner to act on their behalf
         });

        return (depositUsers, redeemUsers);
    }

    /// @dev - transfer from the owner of the IERC20 `token` to the `toAddress`
    function _transferFromTokenOwner(IERC20 token, address toAddress, uint256 amount) internal {
        // only works with Ownable token - need to override otherwise
        Ownable ownableToken = Ownable(address(token));

        _transferAndAssert(token, ownableToken.owner(), toAddress, amount);
    }

    /// @dev - transfer from the `fromAddress` to the `toAddress`
    function _transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
