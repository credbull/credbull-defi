//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console2 } from "forge-std/console2.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IProduct } from "../IProduct.sol";

contract YieldSubscription is IProduct {
    using EnumerableSet for EnumerableSet.UintSet;

    // In wad unit
    uint256 public constant FIXED_YIELD = 6 ether;
    uint256 public constant FIXED_YIELD_ROLL_OVER = 7 ether;
    address public asset;

    uint256 public startTime;
    uint256 public timePeriodsElapsed;
    uint256 public maturityPeriod;
    uint256 public coolDownPeriod;

    mapping(address => mapping(uint256 => uint256)) public userReserve;
    mapping(address => EnumerableSet.UintSet) private userWindows;

    constructor(address _asset, uint256 _startTime, uint256 _maturiyPeriod, uint256 _coolDownPeriod) {
        asset = _asset;
        startTime = _startTime;
        maturityPeriod = _maturiyPeriod;
        coolDownPeriod = _coolDownPeriod;
    }

    function deposit(uint256 assets, address receiver) public returns (uint256) {
        IERC20(asset).transferFrom(msg.sender, address(this), assets);
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        userReserve[receiver][currentWindow] += assets;
        userWindows[receiver].add(currentWindow);
        return assets;
    }

    function redeemAtPeriod(uint256 shares, address receiver, address owner, uint256 redeemTimePeriod) public returns(uint256) {
        address user = msg.sender;
        uint256 balance = userReserve[user][redeemTimePeriod];
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        uint256 noOfWindowsPassed = currentWindow - redeemTimePeriod;
        require(balance > 0, "YieldSubscription: No balance to withdraw");
        require(shares <= balance, "YieldSubscription: Amount exceeds the balance");
        require(noOfWindowsPassed >= maturityPeriod, "YieldSubscription: Withdrawal not allowed before tenure maturity");

        uint256 interestEarned = interestEarnedForWindowForAmount(user, shares, redeemTimePeriod);

        if (shares == balance) {
            userWindows[user].remove(redeemTimePeriod);
            userReserve[user][redeemTimePeriod] = 0;
        } else {
            userReserve[user][redeemTimePeriod] -= shares;
        }

        IERC20(asset).transfer(receiver, shares + interestEarned);

        return shares + interestEarned;
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        address user = msg.sender;
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        uint256 length = userWindows[user].length();
        uint256 eligibleAmount = calculateEligibleAmount(user);

        if (eligibleAmount > 0) {
            require(shares <= eligibleAmount, "YieldSubscription: Amount exceeds the eligible amount");
            for (uint256 i = 0; i < length; i++) {
                uint256 window = userWindows[user].at(i);
                if (window < currentWindow) {
                    uint256 balance = userReserve[user][window] + interestEarnedForWindow(user, window);
                    if (shares > balance) {
                        shares -= balance;
                        userReserve[user][window] = 0;
                        userWindows[user].remove(window);
                    } else {
                        userReserve[user][window] -= shares;
                        break;
                    }
                }
            }
            IERC20(asset).transfer(receiver, shares);
        }

        return shares;
    }

    function calculateEligibleAmount(address user) public view returns (uint256 amountToTransfer) {
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        uint256 length = userWindows[user].length();

        for (uint256 i = 0; i < length; i++) {
            uint256 window = userWindows[user].at(i);
            uint256 noOfWindowsPassed = currentWindow - window;
            if (noOfWindowsPassed <= maturityPeriod) {
                continue;
            }
            amountToTransfer += (userReserve[user][window] + interestEarnedForWindow(user, window));
        }
    }

    function totalInterestEarned(address user) public view returns (uint256) {
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        uint256 length = userWindows[user].length();
        uint256 interestEarned;

        for (uint256 i = 0; i < length; i++) {
            uint256 window = userWindows[user].at(i);
            if (window < currentWindow) {
                interestEarned += interestEarnedForWindow(user, window);
            }
        }
        return interestEarned;
    }

    function totalUserDeposit(address user) public view returns (uint256) {
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        uint256 length = userWindows[user].length();
        uint256 totalDeposit;

        for (uint256 i = 0; i < length; i++) {
            uint256 window = userWindows[user].at(i);
            if (window <= currentWindow) {
                totalDeposit += userReserve[user][window];
            }
        }
        return totalDeposit;
    }

    function interestEarnedForWindow(address user, uint256 window) public view returns (uint256) {
        uint256 userDeposit = userReserve[user][window];
        uint256 noOfWindowsPassed = getCurrentTimePeriodsElapsed() - window;

        console2.log("No of windows passed: %s", noOfWindowsPassed);

        if (noOfWindowsPassed > maturityPeriod) {
            uint256 interestEarnedBeofreRollOver = (userDeposit * yieldPerWindow() * maturityPeriod) / 1e20;   
            return (
                interestEarnedBeofreRollOver
                    + ((userDeposit + interestEarnedBeofreRollOver) * yieldPerWindowRollOver() * (noOfWindowsPassed - maturityPeriod)) / 1e20
            );
        }
        return ((userDeposit) * (yieldPerWindow() * noOfWindowsPassed)) / 1e20;
    }

    function interestEarnedForWindowForAmount(address user, uint256 amount, uint256 window)
        public
        view
        returns (uint256)
    {
        uint256 userDeposit = userReserve[user][window];
        if (amount > userDeposit) {
            return interestEarnedForWindow(user, window);
        }
        userDeposit = amount;
        uint256 noOfWindowsPassed = getCurrentTimePeriodsElapsed() - window;

        if (noOfWindowsPassed > maturityPeriod) {
            return (
                (userDeposit * yieldPerWindow() * maturityPeriod)
                    + (userDeposit * yieldPerWindowRollOver() * (noOfWindowsPassed - maturityPeriod))
            ) / 1e20;
        }
        return ((userDeposit) * (yieldPerWindow() * noOfWindowsPassed)) / 1e20;
    }

    function balanceWithInterest(address user) public view returns (uint256) {
        return totalUserDeposit(user) + totalInterestEarned(user);
    }

    function yieldPerWindow() public pure returns (uint256) {
        return ((FIXED_YIELD) / (365));
    }

    function yieldPerWindowRollOver() public pure returns (uint256) {
        return ((FIXED_YIELD_ROLL_OVER) / (365));
    }

    function getCurrentTimePeriodsElapsed() public view returns (uint256 currentTimePeriodsElapsed) {
        // uint256 timeDifference = block.timestamp - startTime;
        // return (timeDifference / 1 days) + 1;
        return timePeriodsElapsed;
    }

    function getFrequency() public view returns (uint256 frequency) {
        return 1 days;
    }

    function getInterestInPercentage() public view returns (uint256 interestRateInPercentage) {
        interestRateInPercentage = FIXED_YIELD / 1e18;
    }

    function transferBalance(uint256 amount, uint256 window, address to) public {
        address user = msg.sender;
        uint256 balance = userReserve[user][window];
        require(balance > 0, "YieldSubscription: No balance to transfer");
        require(amount <= balance, "YieldSubscription: Amount exceeds the balance");

        if (amount == balance) {
            userWindows[user].remove(window);
            userReserve[user][window] = 0;
        } else {
            userReserve[user][window] -= amount;
        }

        if (userReserve[to][window] == 0) {
            userWindows[to].add(window);
        }
        userReserve[to][window] += amount;
    }

    function getUserWindows(address user) public view returns (uint256[] memory) {
        uint256 length = userWindows[user].length();
        uint256[] memory windows = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            windows[i] = userWindows[user].at(i);
        }
        return windows;
    }

    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /********** Only for DEBUG ********/
    function setStartTime(uint256 _startTime) public {
        startTime = _startTime;
    }

    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) public {
        timePeriodsElapsed = currentTimePeriodsElapsed;
    }
}
