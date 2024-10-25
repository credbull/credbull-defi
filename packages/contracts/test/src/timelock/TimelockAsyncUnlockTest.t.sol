// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SimpleTimelockAsyncUnlockV2 } from "@test/test/timelock/SimpleTimelockAsyncUnlockV2.t.sol";
import { ERC1155MintableBurnable } from "@test/test/token/ERC1155/ERC1155MintableBurnable.t.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";

import { Test } from "forge-std/Test.sol";

contract TimelockAsyncUnlockBase {
    uint256 public constant MAX_COUNT = 10;
    uint256 public constant INITIAL_AMOUNT = 250000;

    function _generate1(uint256 length) internal pure returns (uint256[] memory, uint256[] memory) {
        length = length % MAX_COUNT;

        uint256[] memory depositPeriods = new uint256[](length);
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            depositPeriods[i] = i + 1;
            amounts[i] = i % 2 == 0
                ? (INITIAL_AMOUNT > (1000 * i) ? INITIAL_AMOUNT - (1000 * i) : 0)
                : INITIAL_AMOUNT + (1000 * i);
        }

        return (depositPeriods, amounts);
    }
}

contract TimelockAsyncUnlockTest is Test, TimelockAsyncUnlockBase {
    /**
     * @dev Allows flexibility by not defining a specific instance.
     *      This enables the use of any contract instance derived from `TimelockAsyncUnlock`,
     *      making it adaptable for testing various derived contracts.
     */
    address internal asyncUnlock;
    uint256 internal noticePeriod;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        noticePeriod = 1;
        asyncUnlock = _deployTimelockAsyncUnlock(noticePeriod);
    }

    function testFuzz__TimelockAsyncUnlock__LockAmount(address account, uint256 noOfPeriods) public {
        vm.assume(noOfPeriods > 0);
        vm.assume(account != address(0));

        (uint256[] memory depositPeriods, uint256[] memory amounts) = _generate1(noOfPeriods);

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            _lockAmount(account, depositPeriods[i], amounts[i]);
        }
    }

    function test__TimelockAsyncUnlock__RequestUnlockInvalidArrayLength() public {
        // ======== generate depositPeriods and amounts ========
        uint256[] memory depositPeriods = new uint256[](2);
        depositPeriods[0] = 0;
        depositPeriods[1] = 1;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1000;
        // ============ end =============

        // depositPeriods length and amounts length are different, expect revert
        _requestUnlock(alice, alice, depositPeriods, amounts);
    }

    function test__TimelockAsyncUnlock__RequestUnlockAuthorizeCallerFailed() public {
        // ======== generate depositPeriods and amounts ========
        uint256[] memory depositPeriods = new uint256[](2);
        depositPeriods[0] = 0;
        depositPeriods[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000;
        amounts[1] = 1000;
        // ============ end =============

        // Caller(alice) and owner(bob) are different, expect revert
        _requestUnlock(alice, bob, depositPeriods, amounts);
    }

    function _lockAmount(address user, uint256 depositPeriod, uint256 lockAmount) internal virtual {
        TimelockAsyncUnlock asyncUnlockInst = TimelockAsyncUnlock(asyncUnlock);
        uint256 prevLockedAmount = asyncUnlockInst.lockedAmount(user, depositPeriod);
        uint256 prevMaxRequestUnlock = asyncUnlockInst.maxRequestUnlock(user, depositPeriod);

        vm.prank(user);
        SimpleTimelockAsyncUnlockV2(asyncUnlock).deposit(user, depositPeriod, lockAmount);

        assertEq(prevLockedAmount + lockAmount, asyncUnlockInst.lockedAmount(user, depositPeriod));
        assertEq(prevMaxRequestUnlock + lockAmount, asyncUnlockInst.maxRequestUnlock(user, depositPeriod));
    }

    function _unlock(address caller, address user, uint256 requestId) internal virtual {
        TimelockAsyncUnlock asyncUnlockInst = TimelockAsyncUnlock(asyncUnlock);
        bool failed;

        (uint256[] memory requestDepositPeriods, uint256[] memory requestAmounts) =
            asyncUnlockInst.unlockRequests(user, requestId);

        uint256[] memory prevUnlockRequestAmounts = new uint256[](requestDepositPeriods.length);

        for (uint256 i = 0; i < requestDepositPeriods.length; ++i) {
            prevUnlockRequestAmounts[i] =
                asyncUnlockInst.unlockRequestAmountByDepositPeriod(user, requestDepositPeriods[i]);
        }

        if (caller != user) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    TimelockAsyncUnlock.TimelockAsyncUnlock__AuthorizeCallerFailed.selector, caller, user
                )
            );
            failed = true;
        } else if (requestId > asyncUnlockInst.currentPeriod()) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeUnlockPeriod.selector,
                    caller,
                    user,
                    asyncUnlockInst.currentPeriod(),
                    requestId
                )
            );
            failed = true;
        } else {
            for (uint256 i = 0; i < requestDepositPeriods.length; ++i) {
                if (requestId < requestDepositPeriods[i]) {
                    vm.expectRevert(
                        abi.encodeWithSelector(
                            TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeDepositPeriod.selector,
                            caller,
                            user,
                            requestDepositPeriods[i],
                            requestId
                        )
                    );
                    failed = true;
                    break;
                }
            }
        }
        vm.prank(caller);
        asyncUnlockInst.unlock(user, requestId);

        // in the case of success
        if (!failed) {
            /**
             * Need to add MaxRequestUnlock; It's different based on redeem or unlock
             */
            for (uint256 i = 0; i < requestDepositPeriods.length; ++i) {
                assertEq(
                    prevUnlockRequestAmounts[i] - requestAmounts[i],
                    asyncUnlockInst.unlockRequestAmountByDepositPeriod(user, requestDepositPeriods[i])
                );
            }
        }
    }

    function _requestUnlock(address caller, address user, uint256[] memory _depositPeriods, uint256[] memory _amounts)
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
        } else if (caller != user) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    TimelockAsyncUnlock.TimelockAsyncUnlock__AuthorizeCallerFailed.selector, caller, user
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
        vm.prank(caller);
        uint256 requestId = asyncUnlockInst.requestUnlock(user, _depositPeriods, _amounts);

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

            //sume of araay
            uint256 sumOfAmounts;
            for (uint256 i = 0; i < _depositPeriods.length; ++i) {
                sumOfAmounts += _amounts[i];
            }

            assertEq(sumOfAmounts, asyncUnlockInst.unlockRequestAmount(user, requestId));

            (uint256[] memory requestDepositPeriods, uint256[] memory requestAmounts) =
                asyncUnlockInst.unlockRequests(user, requestId);

            assertEq(requestDepositPeriods, _depositPeriods);
            assertEq(requestAmounts, _amounts);

            //unlockRequestDepositPeriods
            uint256[] memory requestDepositPeriodsOnly = asyncUnlockInst.unlockRequestDepositPeriods(user, requestId);
            assertEq(requestDepositPeriodsOnly, _depositPeriods);
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

    // util functions
    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = element;
    }
}
