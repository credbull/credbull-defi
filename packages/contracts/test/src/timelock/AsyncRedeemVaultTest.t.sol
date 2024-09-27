// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1155MintableBurnable } from "@test/test/token/ERC1155/ERC1155MintableBurnable.t.sol";
import { SimpleTimelockAsyncUnlock } from "@test/test/timelock/SimpleTimelockAsyncUnlock.t.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";

import { Deposit } from "@test/src/timelock/TimelockTest.t.sol";
import { Test } from "forge-std/Test.sol";

contract AsyncRedeemVault is SimpleTimelockAsyncUnlock {
    constructor(uint256 noticePeriod_, IERC5679Ext1155 deposits) SimpleTimelockAsyncUnlock(noticePeriod_, deposits) { }

    function redeemPrincipal(address tokenOwner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount) public {
        // will call out to _updateLockAfterUnlock(tokenOwner, depositPeriod, amount);
        unlock(tokenOwner, depositPeriod, unlockPeriod, amount);

        DEPOSITS.burn(tokenOwner, depositPeriod, amount, _emptyBytesArray());

        // in real impl, safeTransfer the principal
    }

    function redeemYieldOnly(address tokenOwner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount) public {
        // will call out to _updateLockAfterUnlock(tokenOwner, depositPeriod, amount);
        unlock(tokenOwner, depositPeriod, unlockPeriod, amount);

        // move the lock by burning and minting/locking in a new period
        DEPOSITS.burn(tokenOwner, depositPeriod, amount, _emptyBytesArray());
        lock(tokenOwner, currentPeriod(), amount);

        // in real impl, safeTransfer the yield
    }

    function _updateLockAfterUnlock(address, /* account */ uint256, /* depositPeriod */ uint256 amount)
        internal
        virtual
        override
    // solhint-disable-next-line no-empty-blocks
    { }
}

contract AsyncRedeemVaultTest is Test {
    AsyncRedeemVault internal asyncUnlock;
    IERC5679Ext1155 private deposits;

    uint256 private constant NOTICE_PERIOD = 1;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    Deposit private depositDay1 = Deposit({ depositPeriod: 1, amount: 101 });
    Deposit private depositDay2 = Deposit({ depositPeriod: 2, amount: 202 });
    Deposit private depositDay3 = Deposit({ depositPeriod: 3, amount: 303 });

    function setUp() public {
        deposits = new ERC1155MintableBurnable();
        asyncUnlock = new AsyncRedeemVault(NOTICE_PERIOD, deposits);
    }

    function test__RequestRedeemTest__RedeemPrincipal() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        uint256 redeemPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // request unlock
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, redeemPeriod, depositDay1.amount);

        asyncUnlock.setCurrentPeriod(redeemPeriod); // warp ahead

        // now redeem
        vm.prank(alice);
        asyncUnlock.redeemPrincipal(alice, depositDay1.depositPeriod, redeemPeriod, depositDay1.amount);

        assertEq(0, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit lock not released");
        assertEq(0, asyncUnlock.DEPOSITS().balanceOf(alice, depositDay1.depositPeriod), "deposits should be redeemed");
        assertEq(
            0, asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod).amount, "unlockRequest should be released"
        );
    }

    function test__RequestRedeemTest__RedeemYield() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        uint256 redeemPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // request unlock
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, redeemPeriod, depositDay1.amount);

        asyncUnlock.setCurrentPeriod(redeemPeriod); // warp ahead

        // now redeem
        vm.prank(alice);
        asyncUnlock.redeemYieldOnly(alice, depositDay1.depositPeriod, redeemPeriod, depositDay1.amount);

        // lock should be moved to the redeemPeriod
        assertEq(
            depositDay1.amount, asyncUnlock.lockedAmount(alice, redeemPeriod), "deposit not locked at redeemPeriod"
        );
        assertEq(
            0, asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod).amount, "unlockRequest should be released"
        );
    }
}
