// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { CalcInterestMetadata } from "@credbull/yield/CalcInterestMetadata.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { SimpleInterestYieldStrategy } from "@test/test/yield/strategy/SimpleInterestYieldStrategy.sol";
import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract SimpleInterestYieldStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    function test__SimpleInterestYieldStrategy__CalculateYield() public {
        uint256 apy = 6 * SCALE; // APY in percentage
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IYieldStrategy yieldStrategy = new SimpleInterestYieldStrategy(IYieldStrategy.RangeInclusion.To);
        address interestContractAddress = address(_createInterestMetadata(apy, frequency));

        uint256 principal = 500 * SCALE;

        // 500 * (6% / 360) * 1
        assertApproxEqAbs(
            83_333,
            yieldStrategy.calcYield(interestContractAddress, principal, 0, 1),
            TOLERANCE,
            "yield wrong at period 0 to 1"
        );
        // 500 * (6% / 360) * 2
        assertApproxEqAbs(
            166_667,
            yieldStrategy.calcYield(interestContractAddress, principal, 1, 3),
            TOLERANCE,
            "yield wrong at period 1 to 3"
        );
        // 500 * (6% / 360) * 30
        assertApproxEqAbs(
            2_500_000,
            yieldStrategy.calcYield(interestContractAddress, principal, 1, 31),
            TOLERANCE,
            "yield wrong at period 1 to 31"
        );

        address interest2Addr = address(_createInterestMetadata(apy * 2, frequency)); // double the interest rate
        // 500 * (12% / 360) * 30
        assertApproxEqAbs(
            5_000_000, // yield should also double
            yieldStrategy.calcYield(interest2Addr, principal, 1, 31),
            TOLERANCE,
            "yield wrong at period 1 to 31 - double APY"
        );
    }

    function test__SimpleInterestYieldStrategy__CalculatePrice() public {
        uint256 apy = 12 * SCALE;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IYieldStrategy yieldStrategy = new SimpleInterestYieldStrategy(IYieldStrategy.RangeInclusion.To);
        address interestContractAddress = address(_createInterestMetadata(apy, frequency));

        assertEq(1 * SCALE, yieldStrategy.calcPrice(interestContractAddress, 0), "price wrong at period 0"); // 1 + (0.12 * 0) / 360 = 1
        assertEq(1_000_333, yieldStrategy.calcPrice(interestContractAddress, 1), "price wrong at period 1"); // 1 + (0.12 * 1) / 360 ≈ 1.00033
        assertEq((101 * SCALE / 100), yieldStrategy.calcPrice(interestContractAddress, 30), "price wrong at period 30"); // 1 + (0.12 * 30) / 360 = 1.01
    }

    function test__SimpleInterestYieldStrategy__InvalidContextReverts() public {
        IYieldStrategy yieldStrategy = new SimpleInterestYieldStrategy(IYieldStrategy.RangeInclusion.To);

        vm.expectRevert(abi.encodeWithSelector(IYieldStrategy.IYieldStrategy_InvalidContextAddress.selector));
        yieldStrategy.calcYield(address(0), 1, 1, 1);

        vm.expectRevert(abi.encodeWithSelector(IYieldStrategy.IYieldStrategy_InvalidContextAddress.selector));
        yieldStrategy.calcPrice(address(0), 1);
    }

    function test__SimpleInterestYieldStrategy__InvalidPeriodReverts() public {
        uint256 fromPeriod = 10;
        uint256 invalidToPeriod = 0;

        IYieldStrategy yieldStrategy = new SimpleInterestYieldStrategy(IYieldStrategy.RangeInclusion.To);
        address interestContractAddress = address(_createInterestMetadata(12, 360));

        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector,
                fromPeriod,
                invalidToPeriod,
                yieldStrategy.rangeInclusion()
            )
        );
        yieldStrategy.calcYield(interestContractAddress, 1, fromPeriod, invalidToPeriod);
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
