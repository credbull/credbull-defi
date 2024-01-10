//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract RewardVault is ERC4626 {

    mapping(address => uint256) public sharesToReward;

    constructor(IERC20 asset)
    ERC4626(asset)
    ERC20("Reward", "RWD")
    {}

    function distribute(uint256[] calldata rewards, address[] calldata receivers) public virtual {
        for (uint256 i = 0; i < receivers.length; i++) {
            sharesToReward[receivers[i]] = sharesToReward[receivers[i]] + rewards[i];
            _deposit(_msgSender(), address(this), rewards[i], rewards[i]);
        }
    }

    function claim() public virtual returns (uint256) {
        uint256 reward = sharesToReward[_msgSender()];
        sharesToReward[_msgSender()] = 0;

        _approve(address(this), address(this), reward);
        SafeERC20.safeTransferFrom(this, address(this), _msgSender(), reward);

        withdraw(reward, _msgSender(), _msgSender());
        return reward;
    }
}
