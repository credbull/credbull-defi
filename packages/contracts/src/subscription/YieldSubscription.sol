//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { WadRayMath } from "./libraries/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { YieldToken } from "./YieldToken.sol";
import { console2 } from "forge-std/console2.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract YieldSubscription {
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // In wad unit
    uint256 public constant FIXED_YIELD = 6 ether;
    uint256 public constant FIXED_YIELD_ROLL_OVER = 7 ether;
    address public asset;

    uint256 public startTime;

    mapping(address => mapping(uint256 => uint256)) public userReserve;
    mapping(address => EnumerableSet.UintSet) private userWindows;

    constructor(address _asset, uint256 _startTime) {
        asset = _asset;
        startTime = _startTime;
    }

    function deposit(uint256 amount, address user) public {
        IERC20(asset).transferFrom(user, address(this), amount);
        uint256 currentWindow = getCurrentWindow();
        userReserve[user][currentWindow] += amount;
        userWindows[user].add(currentWindow);
    }

    function withdrawForWindow(address user, uint256 amount, uint256 window) public {
        uint256 balance = userReserve[user][window];
        uint256 currentWindow = getCurrentWindow();
        uint256 noOfWindowsPassed = currentWindow - window;
        require(balance > 0, "YieldSubscription: No balance to withdraw");
        require(amount <= balance, "YieldSubscription: Amount exceeds the balance");
        require(noOfWindowsPassed > 30, "YieldSubscription: Withdrawal not allowed before 30 days");

        if (amount == balance) {
            userWindows[user].remove(window);
            userReserve[user][window] = 0;
        } else {
            userReserve[user][window] -= amount;
        }
        uint256 interestEarned = interestEarnedForWindowForAmount(user, amount, window);
        IERC20(asset).transfer(user, amount + interestEarned);
    }

    function withdraw(uint256 amount, address user) public {
        uint256 currentWindow = getCurrentWindow();
        uint256 length = userWindows[user].length();
        uint256 eligibleAmount = calculateEligibleAmount(user);

        if (eligibleAmount > 0) {
            require(amount <= eligibleAmount, "YieldSubscription: Amount exceeds the eligible amount");
            for (uint256 i = 0; i < length; i++) {
                uint256 window = userWindows[user].at(i);
                if (window < currentWindow) {
                    uint256 balance = userReserve[user][window] + interestEarnedForWindow(user, window);
                    if (amount > balance) {
                        amount -= balance;
                        userReserve[user][window] = 0;
                        userWindows[user].remove(window);
                    } else {
                        userReserve[user][window] -= amount;
                        break;
                    }
                }
            }
            IERC20(asset).transfer(user, amount);
        }
    }

    function calculateEligibleAmount(address user) public view returns (uint256 amountToTransfer) {
        uint256 currentWindow = getCurrentWindow();
        uint256 length = userWindows[user].length();

        for (uint256 i = 0; i < length; i++) {
            uint256 window = userWindows[user].at(i);
            uint256 noOfWindowsPassed = currentWindow - window;
            if (noOfWindowsPassed <= 30) {
                continue;
            }
            amountToTransfer += (userReserve[user][window] + interestEarnedForWindow(user, window));
        }
    }

    function totalInterestEarned(address user) public view returns (uint256) {
        uint256 currentWindow = getCurrentWindow();
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
        uint256 currentWindow = getCurrentWindow();
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
        uint256 noOfWindowsPassed = getCurrentWindow() - window;

        if (noOfWindowsPassed > 30) {
            return (
                (userDeposit * yieldPerWindow() * 30)
                    + (userDeposit * yieldPerWindowRollOver() * (noOfWindowsPassed - 30))
            ) / 1e20;
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
        uint256 noOfWindowsPassed = getCurrentWindow() - window;

        if (noOfWindowsPassed > 30) {
            return (
                (userDeposit * yieldPerWindow() * 30)
                    + (userDeposit * yieldPerWindowRollOver() * (noOfWindowsPassed - 30))
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

    function getCurrentWindow() public view returns (uint256) {
        uint256 timeDifference = block.timestamp - startTime;
        return (timeDifference / 1 days) + 1;
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
}
