//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console2 } from "forge-std/console2.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IProduct } from "./IProduct.sol";

contract YieldSubscription is IProduct {
    using EnumerableSet for EnumerableSet.UintSet;

    // In wad unit
    // Here - Fixed the yields to be 0.6 & 0.7 instead of 6 & 7
    uint256 public constant FIXED_YIELD = 0.6 ether;
    uint256 public constant FIXED_YIELD_ROLL_OVER = 0.7 ether;
    // Here - Created a new constant to present the number of days per tenor
    uint256 public constant NO_OF_DAYS = 30;
    address public asset;

    uint256 public startTime;
    uint256 public timePeriodsElapsed;

    // Here - Fixed the precision to align with the token decimals - From 1e20 to 1e18
    uint256 constant PRECISION = 1e18;

    mapping(address => mapping(uint256 => uint256)) public userReserve;
    mapping(address => EnumerableSet.UintSet) private userWindows;

    // Here - Created a new struct to use it in redeem() function
    struct RedeemInfo {
        uint256 shares;
        uint256 totalInterestEarned;
    }

    constructor(address _asset, uint256 _startTime) {
        asset = _asset;
        startTime = _startTime;
    }

    function deposit(uint256 assets, address receiver) public returns (uint256) {
        IERC20(asset).transferFrom(msg.sender, address(this), assets);
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        userReserve[receiver][currentWindow] += assets;
        userWindows[receiver].add(currentWindow);
        return assets;
    }

    function redeemAtPeriod(uint256 shares, address receiver, address owner, uint256 redeemTimePeriod) public returns(uint256) {
        // Here - Added a new require to make sure user doesn't redeem for a future window
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        require(currentWindow > redeemTimePeriod, "YieldSubscription: Withdrawal for chosen window not allowed");
        address user = msg.sender;
        uint256 balance = userReserve[user][redeemTimePeriod];
        uint256 noOfWindowsPassed = currentWindow - redeemTimePeriod;
        require(balance > 0, "YieldSubscription: No balance to withdraw");
        require(shares <= balance, "YieldSubscription: Amount exceeds the balance");
        require(noOfWindowsPassed >= NO_OF_DAYS, "YieldSubscription: Withdrawal not allowed before 30 days");

        // Here - Calculate the interest earned before deducting the shares from the user deposits
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
        uint256 length = userWindows[user].length();
        uint256 eligibleAmount = calculateEligibleAmount(user);

        // Here - Replaced the if() condition with a require
        require(eligibleAmount > 0, "YieldSubscription: Not eligible to redeem");
        require(shares <= eligibleAmount, "YieldSubscription: Amount exceeds the eligible amount");
        RedeemInfo memory redeemInfo = RedeemInfo({
            shares: shares,
            totalInterestEarned: 0
        });

        // Here - We were getting a "Out of bound Panic(5)" exception
        // Because any change on the userWindows struct (Like remove a window) affects the for loop
        // For example:
        // - If the user has 2 windows
        // - at the first iteration we get the (i = 0)
        // - we get the balance & interest for window (userWindows[user].at(i = 0) = 5) and removed it
        // - now the user has 1 window
        // - but the index in the second iteration we get (i = 1) => "Out of Bound" exception
        uint256[] memory _userWindows = new uint256[](length);
        // Here - We copied the userWindows[user] to an array
        for (uint256 i = 0; i < length; i++) {
            _userWindows[i] = userWindows[user].at(i);
        }
        for (uint256 i = 0; i < length; i++) {
            uint256 window = _userWindows[i];
            // Here - Got the noOfWindowsPassed and include it in the next if() condition
            // So the user couldn't withdraw money that he deposited before less than 30 days
            uint256 noOfWindowsPassed = getCurrentTimePeriodsElapsed() - window;
            if (window < getCurrentTimePeriodsElapsed() && noOfWindowsPassed >= NO_OF_DAYS) {
                // Here - The balance will be only the userReserve insted of adding the interest to it
                uint256 balance = userReserve[user][window];
                uint256 interestEarned = interestEarnedForWindowForAmount(user, shares, window);
                // Here - Then will commulativly add the interest to the totalInterestEarned
                redeemInfo.totalInterestEarned += interestEarned;

                if (shares > balance) {
                    shares -= balance;
                    userReserve[user][window] = 0;
                    userWindows[user].remove(window);
                } else {
                    userReserve[user][window] -= shares;
                    if (userReserve[user][window] == 0) {
                        // Here - Will remove the window if its balance reached 0
                        userWindows[user].remove(window);
                    }
                    break;
                }
            }
        }
        // Here - Will transfer the shares + the total interest to the user instead of transferring only the shares
        IERC20(asset).transfer(receiver, redeemInfo.shares + redeemInfo.totalInterestEarned);
        // Here - Will return the shares + the total interest instead of transferring only the shares
        return redeemInfo.shares + redeemInfo.totalInterestEarned;
    }

    function calculateEligibleAmount(address user) public view returns (uint256 amountToTransfer) {
        uint256 currentWindow = getCurrentTimePeriodsElapsed();
        uint256 length = userWindows[user].length();

        for (uint256 i = 0; i < length; i++) {
            uint256 window = userWindows[user].at(i);
            uint256 noOfWindowsPassed = currentWindow - window;
            // Here - Changed the condition from <= to <
            // Please check if it's correct
            if (noOfWindowsPassed < NO_OF_DAYS) {
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

    // Here - Helper function to help us calculate the interest without rolling over internally
    function interestEarnedBeofreRollOver(uint256 userDeposit, uint256 noOfWindowsPassed) internal pure returns(uint256) {
        return (userDeposit * yieldPerWindow() * noOfWindowsPassed) / PRECISION;
    }

    // Here - Helper function to help us calculate the interest after rolling over internally
    function interestEarnedAfterRollOver(uint256 userDeposit, uint256 noOfWindowsPassed) internal pure returns(uint256) {
        uint256 _interestEarnedBeofreRollOver = interestEarnedBeofreRollOver(userDeposit, NO_OF_DAYS);
        return ((userDeposit + _interestEarnedBeofreRollOver) * yieldPerWindowRollOver() * (noOfWindowsPassed - NO_OF_DAYS)) / PRECISION;
    }

    function interestEarnedForWindow(address user, uint256 window) public view returns (uint256) {
        uint256 userDeposit = userReserve[user][window];
        uint256 noOfWindowsPassed = getCurrentTimePeriodsElapsed() - window;

        if (noOfWindowsPassed > NO_OF_DAYS) {
            // Here - Fix the formula which was giving some big and wrong numbers
            uint256 _interestEarnedBeofreRollOver = interestEarnedBeofreRollOver(userDeposit, NO_OF_DAYS);
            return _interestEarnedBeofreRollOver + interestEarnedAfterRollOver(userDeposit, noOfWindowsPassed);
        }
        return interestEarnedBeofreRollOver(userDeposit, noOfWindowsPassed);
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

        if (noOfWindowsPassed > NO_OF_DAYS) {
            // Here - Format the formula which was giving some big and wrong numbers
            uint256 _interestEarnedBeofreRollOver = interestEarnedBeofreRollOver(userDeposit, NO_OF_DAYS);
            return _interestEarnedBeofreRollOver + interestEarnedAfterRollOver(userDeposit, noOfWindowsPassed);
        }
        return interestEarnedBeofreRollOver(userDeposit, noOfWindowsPassed);
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

    function getFrequency() public pure returns (uint256 frequency) {
        return 1 days;
    }

    function getInterestInPercentage() public pure returns (uint256 interestRateInPercentage) {
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
