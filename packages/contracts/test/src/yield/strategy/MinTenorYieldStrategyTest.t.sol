// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { MinTenorYieldStrategy } from "@credbull/yield/strategy/MinTenorYieldStrategy.sol";

import { CalcInterestMetadata } from "@credbull/yield/CalcInterestMetadata.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Test } from "forge-std/Test.sol";

contract SimpleInterestYieldStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    function test__MinTenorYieldStrategy__MinTenorYield() public {
        uint256 minTenor = 30;

        uint256 fromPeriod = 10;
        uint256 toPeriod = fromPeriod + minTenor;

        IYieldStrategy yieldStrategy = new MinTenorYieldStrategy(minTenor);
        address interestContractAddress = address(_createInterestMetadata(12, 360));

        yieldStrategy.calcYield(interestContractAddress, 1, fromPeriod, toPeriod);
    }

    function test__MinTenorYieldStrategy__LessThanTenorReverts() public {
        uint256 minTenor = 30;

        uint256 fromPeriod = 10;
        uint256 toPeriod = fromPeriod + minTenor - 1;

        IYieldStrategy yieldStrategy = new MinTenorYieldStrategy(minTenor);
        address interestContractAddress = address(_createInterestMetadata(12, 360));

        vm.expectRevert(
            abi.encodeWithSelector(
                MinTenorYieldStrategy.MinTenorYieldStrategy_TenorNotReached.selector, fromPeriod, toPeriod, minTenor
            )
        );
        yieldStrategy.calcYield(interestContractAddress, 1, fromPeriod, toPeriod);
    }

    function _createInterestMetadata(uint256 interestRatePercentage, uint256 frequency)
        private
        returns (CalcInterestMetadataMock interestMetadata)
    {
        interestMetadata = new CalcInterestMetadataMock();
        interestMetadata = CalcInterestMetadataMock(
            address(
                new ERC1967Proxy(
                    address(interestMetadata),
                    abi.encodeWithSelector(
                        interestMetadata.mockInitialize.selector, interestRatePercentage, frequency, DECIMALS
                    )
                )
            )
        );
    }
}

contract CalcInterestMetadataMock is Initializable, UUPSUpgradeable, CalcInterestMetadata {
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override { }

    function mockInitialize(uint256 interestRatePercentage, uint256 frequency, uint256 decimals) public initializer {
        __CalcInterestMetadata_init(interestRatePercentage, frequency, decimals);
    }
}
