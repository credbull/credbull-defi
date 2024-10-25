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

    function _generateDepositPeriodsAndAmounts(uint256 length)
        internal
        pure
        returns (uint256[] memory, uint256[] memory, uint256)
    {
        length = length % MAX_COUNT + 1;

        uint256[] memory depositPeriods = new uint256[](length);
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            depositPeriods[i] = i + 1;
            amounts[i] = i % 2 == 0
                ? (INITIAL_AMOUNT > (1000 * i) ? INITIAL_AMOUNT - (1000 * i) : 0)
                : INITIAL_AMOUNT + (1000 * i);
        }

        return (depositPeriods, amounts, depositPeriods.length);
    }

    function _generateSubDataInternal(
        uint256[] memory depositPeriods,
        uint256[] memory amounts,
        uint256 randomSeed,
        bool useLargerAmount
    ) internal pure returns (uint256[] memory, uint256[] memory) {
        uint256 subArrayLength = (randomSeed % depositPeriods.length) + 1;

        uint256[] memory subDepositPeriods = new uint256[](subArrayLength);
        uint256[] memory subAmounts = new uint256[](subArrayLength);

        bool[] memory usedIndices = new bool[](depositPeriods.length);

        uint256 indexForLargerAmount = randomSeed % subArrayLength;

        for (uint256 i = 0; i < subArrayLength; ++i) {
            uint256 index;

            do {
                randomSeed = uint256(keccak256(abi.encode(randomSeed, i)));
                index = randomSeed % depositPeriods.length;
            } while (usedIndices[index]);

            usedIndices[index] = true;

            subDepositPeriods[i] = depositPeriods[index];

            if (useLargerAmount && i == indexForLargerAmount) {
                subAmounts[i] = amounts[index] + (randomSeed % 1000) + 1;
            } else {
                subAmounts[i] = (amounts[index] > 0) ? ((randomSeed % amounts[index]) + 1) : 1;
            }
        }

        return (subDepositPeriods, subAmounts);
    }

    function _generateSubData(uint256[] memory depositPeriods, uint256[] memory amounts, uint256 randomSeed)
        internal
        pure
        returns (uint256[] memory, uint256[] memory)
    {
        return _generateSubDataInternal(depositPeriods, amounts, randomSeed, false);
    }

    function _generateSubDataWithLargerAmountAtIndex(
        uint256[] memory depositPeriods,
        uint256[] memory amounts,
        uint256 randomSeed
    ) internal pure returns (uint256[] memory, uint256[] memory) {
        return _generateSubDataInternal(depositPeriods, amounts, randomSeed, true);
    }

    function _includes(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                return true;
            }
        }
        return false;
    }

    function _includesAll(uint256[] memory arr, uint256[] memory values) internal pure returns (bool) {
        for (uint256 i = 0; i < values.length; i++) {
            if (!_includes(arr, values[i])) {
                return false;
            }
        }
        return true;
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
        // We can change this state
        noticePeriod = 5;
        asyncUnlock = _deployTimelockAsyncUnlock(noticePeriod);
    }

    // ==================== Unit Test/Fuzzing Test ====================
    function testFuzz__TimelockAsyncUnlock__LockAmount(uint256 noOfPeriods) public {
        vm.assume(noOfPeriods > 0);

        (uint256[] memory depositPeriods, uint256[] memory amounts,) = _generateDepositPeriodsAndAmounts(noOfPeriods);

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            _lockAmountWithAssertion(alice, depositPeriods[i], amounts[i]);
        }
    }

    function test__TimelockAsyncUnlock__RequestUnlock__InvalidArrayLength() public {
        uint256[] memory depositPeriods = new uint256[](2);
        depositPeriods[0] = 0;
        depositPeriods[1] = 1;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1000;

        // depositPeriods length and amounts length are different, expect revert
        _requestUnlockWithAssertion(alice, alice, depositPeriods, amounts);
    }

    function testFuzz__TimelockAsyncUnlock__RequestUnlock__AuthorizeCallerFailed(address caller) public {
        vm.assume(caller != address(0) && caller != alice);

        (uint256[] memory depositPeriods, uint256[] memory amounts,) = _generateDepositPeriodsAndAmounts(2);

        // caller and owner(alice) are different, expect revert
        _requestUnlockWithAssertion(caller, alice, depositPeriods, amounts);
    }

    function testFuzz__TimelockAsyncUnlock__RequestUnlock__ExceededMaxRequestUnlock(
        uint256 noOfPeriods,
        uint256 requestUnlockSeed
    ) public {
        vm.assume(noOfPeriods > 0);

        (uint256[] memory depositPeriods, uint256[] memory amounts,) = _generateDepositPeriodsAndAmounts(noOfPeriods);
        _lockAmountBatchWithAssertion(alice, depositPeriods, amounts);

        (uint256[] memory ruDepositPeriods, uint256[] memory ruAmounts) =
            _generateSubDataWithLargerAmountAtIndex(depositPeriods, amounts, requestUnlockSeed);

        _requestUnlockWithAssertion(alice, alice, ruDepositPeriods, ruAmounts);
    }

    function testFuzz__TimelockAsyncUnlock__RequestUnlock(uint256 noOfPeriods, uint256 requestUnlockSeed) public {
        vm.assume(noOfPeriods > 0);

        (uint256[] memory depositPeriods, uint256[] memory amounts,) = _generateDepositPeriodsAndAmounts(noOfPeriods);

        _lockAmountBatchWithAssertion(alice, depositPeriods, amounts);

        (uint256[] memory ruDepositPeriods, uint256[] memory ruAmounts) =
            _generateSubData(depositPeriods, amounts, requestUnlockSeed);

        _requestUnlockWithAssertion(alice, alice, ruDepositPeriods, ruAmounts);
    }

    function testFuzz__TimelockAsyncUnlock__Unlock__AuthorizeCallerFailed(address caller) public {
        vm.assume(caller != address(0) && caller != alice);

        uint256 unlockPeriod = TimelockAsyncUnlock(asyncUnlock).minUnlockPeriod();

        _unlockWithAssertion(caller, alice, unlockPeriod);
    }

    function testFuzz__TimelockAsyncUnlock__Unlock__UnlockBeforeUnlockPeriod(
        uint256 noOfPeriods,
        uint256 unlockSeed,
        uint256 periodOffset
    ) public {
        vm.assume(noOfPeriods > 0);
        (uint256[] memory depositPeriods, uint256[] memory amounts,) = _generateDepositPeriodsAndAmounts(noOfPeriods);
        _lockAmountBatchWithAssertion(alice, depositPeriods, amounts);
        (uint256[] memory ruDepositPeriods, uint256[] memory ruAmounts) =
            _generateSubData(depositPeriods, amounts, unlockSeed);
        _requestUnlockWithAssertion(alice, alice, ruDepositPeriods, ruAmounts);
        TimelockAsyncUnlock asyncUnlockInst = TimelockAsyncUnlock(asyncUnlock);
        uint256 unlockPeriod = asyncUnlockInst.minUnlockPeriod();
        _setCurrentPeriodWithAssertion(
            asyncUnlockInst.currentPeriod() + (periodOffset % asyncUnlockInst.noticePeriod())
        );
        _unlockWithAssertion(alice, alice, unlockPeriod);
    }

    function testFuzz__TimelockAsyncUnlock__Unlock__UnlockBeforeDepositPeriod(uint256 noOfPeriods, uint256 unlockSeed)
        public
    {
        vm.assume(noOfPeriods > 0);

        (uint256[] memory depositPeriods, uint256[] memory amounts,) = _generateDepositPeriodsAndAmounts(noOfPeriods);
        _lockAmountBatchWithAssertion(alice, depositPeriods, amounts);

        (uint256[] memory ruDepositPeriods, uint256[] memory ruAmounts) =
            _generateSubData(depositPeriods, amounts, unlockSeed);

        _requestUnlockWithAssertion(alice, alice, ruDepositPeriods, ruAmounts);

        uint256 unlockPeriod = TimelockAsyncUnlock(asyncUnlock).minUnlockPeriod();

        _setCurrentPeriodWithAssertion(unlockPeriod);

        _unlockWithAssertion(alice, alice, unlockPeriod);
    }

    function testFuzz__TimelockAsyncUnlock__Unlock(uint256 noOfPeriods, uint256 unlockSeed, uint8 periodOffset)
        public
    {
        vm.assume(noOfPeriods > 0);

        (uint256[] memory depositPeriods, uint256[] memory amounts, uint256 maxDepositPeriod) =
            _generateDepositPeriodsAndAmounts(noOfPeriods);

        // Need to put it into modifier
        _setCurrentPeriodWithAssertion(maxDepositPeriod);
        //
        _lockAmountBatchWithAssertion(alice, depositPeriods, amounts);

        (uint256[] memory ruDepositPeriods, uint256[] memory ruAmounts) =
            _generateSubData(depositPeriods, amounts, unlockSeed);

        _requestUnlockWithAssertion(alice, alice, ruDepositPeriods, ruAmounts);

        uint256 unlockPeriod = TimelockAsyncUnlock(asyncUnlock).minUnlockPeriod();

        _setCurrentPeriodWithAssertion(unlockPeriod + periodOffset);
        _unlockWithAssertion(alice, alice, unlockPeriod);
    }

    // ==================== Stateful Testing (Advanced Test scenario) ====================
    function test__TimelockAsyncUnlock__MultipleRequestUnlocks__MultipleRequestsAndUnlocks() public {
        uint256[] memory depositPeriods = new uint256[](3);
        depositPeriods[0] = 1;
        depositPeriods[1] = 4;
        depositPeriods[2] = 8;

        uint256[] memory lockAmounts = new uint256[](3);
        lockAmounts[0] = 2000;
        lockAmounts[1] = 1500;
        lockAmounts[2] = 3200;

        _lockAmountBatchWithAssertion(alice, depositPeriods, lockAmounts);

        _setCurrentPeriodWithAssertion(8);

        // first unlock request
        uint256[] memory depositPeriodsForUnlock = new uint256[](2);
        uint256[] memory amountsForUnlock = new uint256[](2);

        depositPeriodsForUnlock[0] = 1;
        depositPeriodsForUnlock[1] = 4;
        amountsForUnlock[0] = 1800;
        amountsForUnlock[1] = 1200;

        _requestUnlockWithAssertion(alice, alice, depositPeriodsForUnlock, amountsForUnlock);

        // second unlock request
        uint256[] memory depositPeriodsForUnlock2 = new uint256[](2);
        uint256[] memory amountsForUnlock2 = new uint256[](2);

        depositPeriodsForUnlock2[0] = 4;
        depositPeriodsForUnlock2[1] = 8;
        amountsForUnlock2[0] = 200;
        amountsForUnlock2[1] = 2000;

        _requestUnlockWithAssertion(alice, alice, depositPeriodsForUnlock2, amountsForUnlock2);

        uint256 unlockPeriod = TimelockAsyncUnlock(asyncUnlock).minUnlockPeriod();
        _setCurrentPeriodWithAssertion(TimelockAsyncUnlock(asyncUnlock).minUnlockPeriod());

        _unlockWithAssertion(alice, alice, unlockPeriod);
    }

    function _lockAmountBatchWithAssertion(address user, uint256[] memory depositPeriods, uint256[] memory lockAmounts)
        internal
    {
        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            _lockAmountWithAssertion(user, depositPeriods[i], lockAmounts[i]);
        }
    }

    function _setCurrentPeriodWithAssertion(uint256 _currentPeriod) internal {
        _setCurrentPeriod(_currentPeriod);

        assertEq(TimelockAsyncUnlock(asyncUnlock).currentPeriod(), _currentPeriod);
        assertEq(
            TimelockAsyncUnlock(asyncUnlock).minUnlockPeriod(),
            _currentPeriod + TimelockAsyncUnlock(asyncUnlock).noticePeriod()
        );
    }

    function _lockAmountWithAssertion(address user, uint256 depositPeriod, uint256 lockAmount) internal {
        TimelockAsyncUnlock asyncUnlockInst = TimelockAsyncUnlock(asyncUnlock);
        uint256 prevLockedAmount = asyncUnlockInst.lockedAmount(user, depositPeriod);
        uint256 prevMaxRequestUnlock = asyncUnlockInst.maxRequestUnlock(user, depositPeriod);

        _lockAmount(user, depositPeriod, lockAmount);

        assertEq(prevLockedAmount + lockAmount, asyncUnlockInst.lockedAmount(user, depositPeriod));
        assertEq(prevMaxRequestUnlock + lockAmount, asyncUnlockInst.maxRequestUnlock(user, depositPeriod));
    }

    function _unlockWithAssertion(address caller, address user, uint256 requestId) internal {
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

        _unlock(caller, user, requestId);

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
        returns (uint256)
    {
        vm.prank(caller);
        uint256 requestId = TimelockAsyncUnlock(asyncUnlock).requestUnlock(user, _depositPeriods, _amounts);
        return requestId;
    }

    function _requestUnlockWithAssertion(
        address caller,
        address user,
        uint256[] memory _depositPeriods,
        uint256[] memory _amounts
    ) internal virtual {
        // TimelockAsyncUnlock asyncUnlockInst = TimelockAsyncUnlock(asyncUnlock);
        bool failed;

        uint256[] memory prevUnlockRequestAmounts = new uint256[](_depositPeriods.length);
        uint256[] memory prevMaxRequestUnlockAmounts = new uint256[](_depositPeriods.length);

        uint256 prevUnlockRequestAmountByRequestId = TimelockAsyncUnlock(asyncUnlock).unlockRequestAmount(
            user, TimelockAsyncUnlock(asyncUnlock).minUnlockPeriod()
        );

        for (uint256 i = 0; i < _depositPeriods.length; ++i) {
            prevUnlockRequestAmounts[i] =
                TimelockAsyncUnlock(asyncUnlock).unlockRequestAmountByDepositPeriod(user, _depositPeriods[i]);
            prevMaxRequestUnlockAmounts[i] = TimelockAsyncUnlock(asyncUnlock).maxRequestUnlock(user, _depositPeriods[i]);
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
                if (_amounts[i] > TimelockAsyncUnlock(asyncUnlock).maxRequestUnlock(user, _depositPeriods[i])) {
                    vm.expectRevert(
                        abi.encodeWithSelector(
                            TimelockAsyncUnlock.TimelockAsyncUnlock__ExceededMaxRequestUnlock.selector,
                            user,
                            _depositPeriods[i],
                            _amounts[i],
                            TimelockAsyncUnlock(asyncUnlock).maxRequestUnlock(user, _depositPeriods[i])
                        )
                    );

                    failed = true;

                    break;
                }
            }
        }

        uint256 requestId = _requestUnlock(caller, user, _depositPeriods, _amounts);

        // in the case of success
        if (!failed) {
            for (uint256 i = 0; i < _depositPeriods.length; ++i) {
                assertEq(
                    prevUnlockRequestAmounts[i] + _amounts[i],
                    TimelockAsyncUnlock(asyncUnlock).unlockRequestAmountByDepositPeriod(user, _depositPeriods[i])
                );

                assertEq(
                    prevMaxRequestUnlockAmounts[i] - _amounts[i],
                    TimelockAsyncUnlock(asyncUnlock).maxRequestUnlock(user, _depositPeriods[i])
                );
            }

            //sume of araay
            uint256 sumOfAmounts;
            for (uint256 i = 0; i < _depositPeriods.length; ++i) {
                sumOfAmounts += _amounts[i];
            }

            assertEq(
                prevUnlockRequestAmountByRequestId + sumOfAmounts,
                TimelockAsyncUnlock(asyncUnlock).unlockRequestAmount(user, requestId)
            );

            (uint256[] memory requestDepositPeriods, /*uint256[] memory requestAmounts*/ ) =
                TimelockAsyncUnlock(asyncUnlock).unlockRequests(user, requestId);

            assertTrue(_includesAll(requestDepositPeriods, _depositPeriods));

            // ToDo; Need to fix it
            // assertEq(requestAmounts, _amounts);

            //unlockRequestDepositPeriods
            uint256[] memory requestDepositPeriodsOnly =
                TimelockAsyncUnlock(asyncUnlock).unlockRequestDepositPeriods(user, requestId);

            // assertEq(requestDepositPeriodsOnly, _depositPeriods);
            assertTrue(_includesAll(requestDepositPeriodsOnly, _depositPeriods));
        }
    }

    // Need to Override in Child contracts
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

    function _lockAmount(address user, uint256 depositPeriod, uint256 lockAmount) internal virtual {
        vm.prank(user);
        SimpleTimelockAsyncUnlockV2(asyncUnlock).deposit(user, depositPeriod, lockAmount);
    }

    function _unlock(address caller, address user, uint256 requestId) internal virtual {
        vm.prank(caller);
        SimpleTimelockAsyncUnlockV2(asyncUnlock).unlock(user, requestId);
    }

    function _setCurrentPeriod(uint256 _currentPeriod) internal virtual {
        SimpleTimelockAsyncUnlockV2(asyncUnlock).setCurrentPeriod(_currentPeriod);
    }
}
