// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SimpleTimelockAsyncUnlockV2 } from "@test/test/timelock/SimpleTimelockAsyncUnlockV2.t.sol";
import { ERC1155MintableBurnable } from "@test/test/token/ERC1155/ERC1155MintableBurnable.t.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";

import { Test } from "forge-std/Test.sol";

contract TimelockAsyncUnlockTest is Test {
    /**
     * @dev Allows flexibility by not defining a specific instance.
     *      This enables the use of any contract instance derived from `TimelockAsyncUnlock`,
     *      making it adaptable for testing various derived contracts.
     */
    address internal asyncUnlock;

    uint256 internal noticePeriod;

    function setUp() public {
        noticePeriod = 1;

        asyncUnlock = _deployTimelockAsyncUnlock(noticePeriod);
    }

    function testFuzz__TimelockAsyncUnlock__LockAmount(uint256 depositPeriod, uint256 lockAmount) public {
        _lockAmount(address(0x43555), depositPeriod, lockAmount);
    }

    function test__TimelockAsyncUnlock__RequestUnlock() public {
        uint256[] memory depositPeriods = new uint256[](2);
        depositPeriods[0] = 0;
        depositPeriods[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000;
        amounts[1] = 2000;

        for (uint256 i = 0; i < depositPeriods.length; i++) {
            _lockAmount(address(0x43555), depositPeriods[i], amounts[i]);
        }

        amounts[0] = 500;
        amounts[1] = 1000;

        _requestUnlock(address(0x43555), depositPeriods, amounts);
    }

    /**
     * @dev deposit/lock
     * This is the 1st action
     */
    function _lockAmount(address user, uint256 depositPeriod, uint256 lockAmount) internal virtual {
        TimelockAsyncUnlock asyncUnlockInst = TimelockAsyncUnlock(asyncUnlock);
        uint256 prevLockedAmount = asyncUnlockInst.lockedAmount(user, depositPeriod);
        uint256 prevMaxRequestUnlock = asyncUnlockInst.maxRequestUnlock(user, depositPeriod);

        vm.prank(user);
        SimpleTimelockAsyncUnlockV2(asyncUnlock).deposit(user, depositPeriod, lockAmount);

        assertEq(prevLockedAmount + lockAmount, asyncUnlockInst.lockedAmount(user, depositPeriod));
        assertEq(prevMaxRequestUnlock + lockAmount, asyncUnlockInst.maxRequestUnlock(user, depositPeriod));
    }

    function _requestUnlock(address user, uint256[] memory _depositPeriods, uint256[] memory _amounts)
        internal
        virtual
    {
        TimelockAsyncUnlock asyncUnlockInst = TimelockAsyncUnlock(asyncUnlock);
        bool failed;

        uint256[] memory prevUnlockRequestAmounts = new uint256[](_depositPeriods.length);
        uint256[] memory prevMaxRequestUnlockAmounts = new uint256[](_depositPeriods.length);

        for (uint256 i = 0; i < _depositPeriods.length; ++i) {
            prevUnlockRequestAmounts[i] = asyncUnlockInst.unlockRequestAmountByDepositPeriod(user, _depositPeriods[i]);
            prevMaxRequestUnlockAmounts[i] = asyncUnlockInst.maxRequestUnlock(user, _depositPeriods[i]);
        }

        if (_depositPeriods.length != _amounts.length) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    TimelockAsyncUnlock.TimelockAsyncUnlock__InvalidArrayLength.selector,
                    _depositPeriods.length,
                    _amounts.length
                )
            );
            failed = true;
        } else {
            for (uint256 i = 0; i < _depositPeriods.length; ++i) {
                if (_amounts[i] > asyncUnlockInst.maxRequestUnlock(user, _depositPeriods[i])) {
                    vm.expectRevert(
                        abi.encodeWithSelector(
                            TimelockAsyncUnlock.TimelockAsyncUnlock__ExceededMaxRequestUnlock.selector,
                            user,
                            _depositPeriods[i],
                            _amounts[i],
                            asyncUnlockInst.maxRequestUnlock(user, _depositPeriods[i])
                        )
                    );

                    failed = true;

                    break;
                }
            }
        }
        vm.prank(user);
        asyncUnlockInst.requestUnlock(user, _depositPeriods, _amounts);

        // in the case of success
        if (!failed) {
            for (uint256 i = 0; i < _depositPeriods.length; ++i) {
                assertEq(
                    prevUnlockRequestAmounts[i] + _amounts[i],
                    asyncUnlockInst.unlockRequestAmountByDepositPeriod(user, _depositPeriods[i])
                );

                assertEq(
                    prevMaxRequestUnlockAmounts[i] - _amounts[i],
                    asyncUnlockInst.maxRequestUnlock(user, _depositPeriods[i])
                );
            }
        }
    }

    function _deployTimelockAsyncUnlock(uint256 noticePeriod_) internal virtual returns (address) {
        IERC5679Ext1155 deposits = new ERC1155MintableBurnable();

        SimpleTimelockAsyncUnlockV2 asyncUnlockInst = new SimpleTimelockAsyncUnlockV2();

        asyncUnlockInst = SimpleTimelockAsyncUnlockV2(
            address(
                new ERC1967Proxy(
                    address(asyncUnlockInst),
                    abi.encodeWithSelector(asyncUnlockInst.initialize.selector, noticePeriod_, deposits)
                )
            )
        );

        return address(asyncUnlockInst);
    }
}
