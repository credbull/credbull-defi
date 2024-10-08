// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

// Tets relation to the Utility / operational aspects of the LiquidContinuousMultiTokenVault
contract LiquidContinuousMultiTokenVaultUtilTest is LiquidContinuousMultiTokenVaultTestBase {
    function test__LiquidContinuousMultiTokenVaultUtil__Upgradeability() public {
        LiquidContinuousMultiTokenVaultMock vaultImpl = new LiquidContinuousMultiTokenVaultMock();
        LiquidContinuousMultiTokenVaultMock vaultProxy = LiquidContinuousMultiTokenVaultMock(
            address(
                new ERC1967Proxy(
                    address(vaultImpl),
                    abi.encodeWithSelector(vaultImpl.mockInitialize.selector, _createVaultParams(_vaultAuth))
                )
            )
        );

        IERC20Metadata asset = IERC20Metadata(vaultProxy.asset());
        uint256 scale = 10 ** asset.decimals();
        _transferAndAssert(asset, _vaultAuth.owner, alice, 1_000_000_000 * scale);

        TestParam memory testParams = TestParam({ principal: 2_000 * scale, depositPeriod: 11, redeemPeriod: 71 });

        uint256 sharesAmount = testParams.principal; // 1 principal = 1 share
        _warpToPeriod(vaultProxy, testParams.depositPeriod);

        vm.startPrank(alice);
        asset.approve(address(vaultProxy), testParams.principal); // grant the vault allowance
        vaultProxy.executeBuy(alice, 0, testParams.principal, sharesAmount);
        vm.stopPrank();

        assertEq(
            testParams.principal,
            vaultProxy.balanceOf(alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );

        //Upgrade contract
        LiquidContinuousMultiTokenVaultMockV2 mockVaultV2 = new LiquidContinuousMultiTokenVaultMockV2();

        vm.prank(_vaultAuth.upgrader);
        vaultProxy.upgradeToAndCall(address(mockVaultV2), "");

        assertEq("2.0.0", mockVaultV2.version(), "version should be 2.0.0");

        assertEq(
            testParams.principal,
            vaultProxy.balanceOf(alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );
    }

    function test__LiquidContinuousMultiTokenVaultUtil__Clock() public {
        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault();
        vault = LiquidContinuousMultiTokenVaultMock(
            address(
                new ERC1967Proxy(
                    address(vault), abi.encodeWithSelector(vault.initialize.selector, _createVaultParams(_vaultAuth))
                )
            )
        );

        assertEq(Timer.CLOCK_MODE(), vault.CLOCK_MODE());
        assertEq(Timer.clock(), vault.clock());

        assertTrue(vault.getVersion() > 0, "version should be nonzero");
        assertTrue(vault.supportsInterface(type(IMultiTokenVault).interfaceId), "should support interface");
    }

    function test__LiquidContinuousMultiTokenVaultUtil__PauseDepositAndRedeem() public {
        TestParam memory testParams =
            TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: _liquidVault.minUnlockPeriod() });

        vm.prank(alice);
        _asset.approve(address(_liquidVault), testParams.principal); // grant vault allowance on alice's principal

        vm.prank(_vaultAuth.owner);
        _transferAndAssert(_asset, _vaultAuth.owner, address(_liquidVault), testParams.principal); // transfer funds to cover redeem

        // ------------ paused deposit ------------
        vm.prank(_vaultAuth.operator);
        _liquidVault.pause();

        vm.prank(alice);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        _liquidVault.deposit(testParams.principal, alice);

        // ------------ unpaused deposit ------------
        vm.prank(_vaultAuth.operator);
        _liquidVault.unpause();

        vm.prank(alice);
        uint256 shares = _liquidVault.deposit(testParams.principal, alice);

        // ------------ paused redeem ------------
        vm.prank(_vaultAuth.operator);
        _liquidVault.pause();

        vm.prank(alice);

        _liquidVault.requestUnlock(alice, _asSingletonArray(testParams.depositPeriod), _asSingletonArray(shares));

        _warpToPeriod(_liquidVault, testParams.redeemPeriod);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        _liquidVault.redeemForDepositPeriod(shares, alice, alice, testParams.depositPeriod, testParams.redeemPeriod);

        // ------------ unpaused redeem ------------
        vm.prank(_vaultAuth.operator);
        _liquidVault.unpause();

        _liquidVault.redeemForDepositPeriod(shares, alice, alice, testParams.depositPeriod, testParams.redeemPeriod);
    }

    function test__LiquidContinuousMultiTokenVaultUtil__UpdateStateVariables() public {
        TripleRateYieldStrategy newYieldStrategy = new TripleRateYieldStrategy();
        RedeemOptimizerFIFO newRedeemOptimizer = new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, 0);
        uint256 newReducedRate = 50;
        uint256 newStartTimestamp = _liquidVault._vaultStartTimestamp() + 1;

        // ------------ fails with wrong operator ------------
        address randomUser = makeAddr("randomUser");
        vm.startPrank(randomUser);

        bytes memory expectedError = abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector, randomUser, _liquidVault.OPERATOR_ROLE()
        );

        vm.expectRevert(expectedError);
        _liquidVault.setYieldStrategy(newYieldStrategy);

        vm.expectRevert(expectedError);
        _liquidVault.setRedeemOptimizer(newRedeemOptimizer);

        vm.expectRevert(expectedError);
        _liquidVault.setVaultStartTimestamp(newStartTimestamp);

        vm.expectRevert(expectedError);
        _liquidVault.setReducedRate(newReducedRate, newStartTimestamp);

        vm.expectRevert(expectedError);
        _liquidVault.setReducedRateAtCurrent(newReducedRate);

        vm.stopPrank();

        // ------------ operator can set ------------

        vm.startPrank(_vaultAuth.operator);
        _liquidVault.setYieldStrategy(newYieldStrategy);
        assertEq(address(newYieldStrategy), address(_liquidVault._yieldStrategy()), "yield strategy not set");

        _liquidVault.setRedeemOptimizer(newRedeemOptimizer);
        assertEq(address(newRedeemOptimizer), address(_liquidVault._redeemOptimizer()), "optimizer not set");

        _liquidVault.setVaultStartTimestamp(newStartTimestamp);
        assertEq(newStartTimestamp, _liquidVault._vaultStartTimestamp(), "start timestamp not set");

        _liquidVault.setReducedRate(newReducedRate, newStartTimestamp);
        assertEq(newStartTimestamp, _liquidVault.currentPeriodRate().effectiveFromPeriod, "effective period not set");
        assertEq(newReducedRate, _liquidVault.currentPeriodRate().interestRate, "rate not set");

        vm.stopPrank();
    }

    function test__LiquidContinuousMultiTokenVaultUtil__UpdateReducedRateAtCurrent() public {
        uint256 newReducedRateAtCurrent = 50;

        _warpToPeriod(_liquidVault, _liquidVault.currentPeriod() + 2);

        vm.prank(_vaultAuth.operator);
        _liquidVault.setReducedRateAtCurrent(newReducedRateAtCurrent);
        assertEq(newReducedRateAtCurrent, _liquidVault.currentPeriodRate().interestRate, "rate not set");
    }

    function test__LiquidContinuousMultiTokenVaultUtil__ZeroAddressAuthReverts() public {
        address zeroAddress = address(0);

        LiquidContinuousMultiTokenVault liquidVault = new LiquidContinuousMultiTokenVault();
        LiquidContinuousMultiTokenVault.VaultParams memory paramsZeroOperator = _createVaultParams(
            LiquidContinuousMultiTokenVault.VaultAuth({
                owner: makeAddr("owner"),
                operator: zeroAddress,
                upgrader: makeAddr("upgrader")
            })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__InvalidAuthAddress.selector,
                "operator",
                zeroAddress
            )
        );

        new ERC1967Proxy(
            address(liquidVault), abi.encodeWithSelector(liquidVault.initialize.selector, paramsZeroOperator)
        );

        LiquidContinuousMultiTokenVault.VaultParams memory paramsZeroUpgrader = _createVaultParams(
            LiquidContinuousMultiTokenVault.VaultAuth({
                owner: makeAddr("owner"),
                operator: makeAddr("operator"),
                upgrader: zeroAddress
            })
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__InvalidAuthAddress.selector,
                "upgrader",
                zeroAddress
            )
        );
        new ERC1967Proxy(
            address(liquidVault), abi.encodeWithSelector(liquidVault.initialize.selector, paramsZeroUpgrader)
        );
    }

    function test__LiquidContinuousMultiTokenVaultUtil__Metadata() public {
        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault();
        vault = LiquidContinuousMultiTokenVaultMock(
            address(
                new ERC1967Proxy(
                    address(vault), abi.encodeWithSelector(vault.initialize.selector, _createVaultParams(_vaultAuth))
                )
            )
        );

        assertTrue(vault.getVersion() > 0, "version should be nonzero");
        assertTrue(vault.supportsInterface(type(IMultiTokenVault).interfaceId), "should support interface");
    }
}

contract LiquidContinuousMultiTokenVaultMock is LiquidContinuousMultiTokenVault {
    constructor() {
        _disableInitializers();
    }

    function mockInitialize(VaultParams memory params) public initializer {
        super.initialize(params);
    }
}

contract LiquidContinuousMultiTokenVaultMockV2 is LiquidContinuousMultiTokenVaultMock {
    function version() public pure returns (string memory) {
        return "2.0.0";
    }
}
