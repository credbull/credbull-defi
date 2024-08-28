//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { YieldSubscription } from "./YieldSubscription.sol";

contract YieldToken is ERC20 {
    YieldSubscription subscription;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) + subscription.interestEarnedForWindow(account, super.balanceOf(account));
    }

    function setsubscription(address _subscription) public {
        subscription = YieldSubscription(_subscription);
    }
}
