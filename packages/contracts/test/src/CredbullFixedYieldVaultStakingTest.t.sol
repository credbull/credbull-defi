//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";
import { DeployStakingVaults } from "@script/DeployStakingVaults.s.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";

import { CBL } from "@credbull/token/CBL.sol";

contract CredbullFixedYieldVaultStakingTest is Test {
    using Math for uint256;

    CredbullFixedYieldVault private vault50APY;
    CredbullFixedYieldVault private vault0APY;
    HelperConfig private helperConfig;

    CBL private cbl;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    address private owner;
    address private operator;
    address private minter;

    uint256 private precision;
    uint256 private constant INITIAL_BALANCE = 1000;

    uint256 private TOLERANCE = 1;

    function setUp() public {
        DeployStakingVaults deployStakingVaults = new DeployStakingVaults();
        (, vault50APY, vault0APY, helperConfig) = deployStakingVaults.run();

        cbl = CBL(vault50APY.asset());
        precision = 10 ** cbl.decimals();

        assertEq(10 ** 18, precision, "should be 10^18");

        owner = helperConfig.getNetworkConfig().factoryParams.owner;
        operator = helperConfig.getNetworkConfig().factoryParams.operator;
        minter = helperConfig.getNetworkConfig().factoryParams.operator;

        vm.startPrank(minter);
        cbl.mint(alice, INITIAL_BALANCE * precision);
        cbl.mint(bob, INITIAL_BALANCE * precision);
        vm.stopPrank();

        assertEq(INITIAL_BALANCE * precision, cbl.balanceOf(alice), "alice didn't receive CBL");
    }

    function test__FixedYieldVaultStakingChallenge__Expect50APY() public {
        uint256 depositAmount = 10 * precision;
        uint256 expectedReturns = depositAmount * 4_167 / 100_000; // 50% APY / 12 months ≈ 4.167% YIELD per month
        uint256 expectedAssets = depositAmount + expectedReturns;

        uint256 aliceShares = depositAndVerify(vault50APY, alice, depositAmount);

        assertEq(vault50APY.totalAssetDeposited(), depositAmount, "assets should be deposits");
        assertEq(vault50APY.totalAssets(), depositAmount, "totalAssets should be deposits");
        assertEq(
            vault50APY.expectedAssetsOnMaturity(),
            expectedAssets,
            "vault expected assets should be a full year of interest"
        );

        assertEq(depositAmount, vault50APY.previewRedeem(depositAmount), "on deposit, preview should be deposits only");

        // =================== mature ===================
        matureVault(vault50APY, expectedAssets);

        assertTrue(vault50APY.isMatured(), "vault should be matured now");
        assertEq(
            vault50APY.totalAssetDeposited(),
            expectedAssets,
            "after maturing, assets should be deposits + 1 year returns"
        );
        assertEq(vault50APY.totalAssets(), expectedAssets, "after maturing, assets should be deposits + 1 year returns");

        assertApproxEqAbs(
            expectedAssets,
            vault50APY.previewRedeem(depositAmount),
            TOLERANCE,
            "after maturing, preview should be deposits + 1 year returns"
        );

        // =================== alice redeem ===================
        redeemAndVerify(vault50APY, alice, aliceShares, expectedAssets);
    }

    function test__FixedYieldVaultStakingChallenge__Expect0APY() public {
        uint256 depositAmount = 10 * precision;

        depositAndVerify(vault0APY, alice, depositAmount);
    }

    function depositAndVerify(CredbullFixedYieldVault vault, address tokenOwner, uint256 depositAmount)
        public
        returns (uint256 shares_)
    {
        uint256 prevCBLCustodian = cbl.balanceOf(vault.CUSTODIAN());
        uint256 prevSharesTokenOwner = vault.balanceOf(tokenOwner);

        _toggleWindowCheck(vault, false);

        vm.startPrank(tokenOwner);
        cbl.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, tokenOwner);
        vm.stopPrank();

        assertEq(prevCBLCustodian + depositAmount, cbl.balanceOf(vault.CUSTODIAN()), "custodian should have the CBL");
        assertEq(prevSharesTokenOwner + shares, vault.balanceOf(tokenOwner), "tokenOwner should have the shares");

        _toggleWindowCheck(vault, true);

        return shares;
    }

    function matureVault(CredbullFixedYieldVault vault, uint256 expectedAssets1Year) public {
        vm.prank(owner);
        vault.setMaturityCheck(true);
        assertTrue(vault.checkMaturity(), "nmaturity check should be on");

        // give the vault enough assets to cover redeems
        vm.startPrank(minter);
        cbl.mint(address(vault), expectedAssets1Year);
        vm.stopPrank();

        vm.prank(operator);
        vault.mature();
    }

    function redeemAndVerify(CredbullFixedYieldVault vault, address tokenOwner, uint256 shares, uint256 expectedAssets)
        public
        returns (uint256 assets_)
    {
        assertTrue(vault.isMatured(), "vault should be matured to redeem");

        _toggleWindowCheck(vault, false);

        address receiver = makeAddr(string.concat(vm.toString(tokenOwner), "randomReceiverWallet"));
        assertEq(0, cbl.balanceOf(receiver), "receiver should start with 0 CBL");

        vm.startPrank(tokenOwner);
        uint256 assets = vault.redeem(shares, receiver, tokenOwner);
        vm.stopPrank();

        assertApproxEqAbs(expectedAssets, assets, TOLERANCE, "asset value incorrect");
        assertApproxEqAbs(expectedAssets, cbl.balanceOf(receiver), TOLERANCE, "receiver should have the CBL");

        _toggleWindowCheck(vault, true);

        return assets;
    }

    function _toggleWindowCheck(CredbullFixedYieldVault vault, bool windowCheckStatus) internal {
        bool isWindowCheckOn = vault.checkWindow();

        if (windowCheckStatus != isWindowCheckOn) {
            vm.prank(owner);
            vault.toggleWindowCheck();
            assertEq(vault.checkWindow(), windowCheckStatus);
        }
    }
}
