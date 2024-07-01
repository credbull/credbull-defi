//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";

import { Vault } from "@credbull/vault/Vault.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract VaultTest is Test {
    using Math for uint256;

    SimpleVault private vault;
    HelperConfig private helperConfig;

    Vault.VaultParams private vaultParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private precision;

    uint256 private constant INITIAL_BALANCE = 1e6;
    uint256 private constant MAX_PERCENTAGE = 100_00;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        vaultParams = new ParamsFactory(helperConfig.getNetworkConfig()).createVaultParams();

        vault = createTestVault(vaultParams);
        precision = 10 ** SimpleUSDC(address(vaultParams.asset)).decimals();

        SimpleUSDC(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        SimpleUSDC(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__Vault__ShareNameAndSymbol() public view {
        assertEq(vault.name(), vaultParams.shareName);
        assertEq(vault.symbol(), vaultParams.shareSymbol);
    }

    function test__Vault__CustodianAddress() public view {
        assertEq(vault.CUSTODIAN(), vaultParams.custodian);
    }

    function test__BaseVault__ShouldRevertOnInvalidAsset() public {
        address zeroAddress = address(0);
        vm.expectRevert(abi.encodeWithSelector(Vault.CredbullVault__InvalidAsset.selector, zeroAddress));
        new SimpleVault(
            Vault.VaultParams({
                asset: IERC20(zeroAddress),
                shareName: "Test",
                shareSymbol: "test",
                custodian: vaultParams.custodian
            })
        );
    }

    function test__BaseVault__ShouldRevertOnInvalidCustodianAddress() public {
        address zeroAddress = address(0);

        vm.expectRevert(abi.encodeWithSelector(Vault.CredbullVault__InvalidCustodianAddress.selector, zeroAddress));
        new SimpleVault(
            Vault.VaultParams({
                asset: vaultParams.asset,
                shareName: "Test",
                shareSymbol: "test",
                custodian: zeroAddress
            })
        );
    }

    function test__BaseVault__ShouldReturnCorrectDecimalValue() public view {
        assertEq(vault.decimals(), SimpleUSDC(address(vaultParams.asset)).decimals());
    }

    function test__BaseVault__DepositAssetsAndGetShares() public {
        uint256 custodiansBalance = vaultParams.asset.balanceOf(vaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User should start with no Shares");

        // ---- Setup Part 2 - Alice Deposit and Receives shares ----
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        // ---- Assert - Vault gets the Assets, Alice gets Shares ----

        // Vault should have the assets
        assertEq(vault.totalAssets(), depositAmount, "Vault should now have the assets");
        assertEq(
            vaultParams.asset.balanceOf(vaultParams.custodian),
            depositAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        // Alice should have the shares
        assertEq(shares, depositAmount, "User should now have the Shares");
        assertEq(vault.balanceOf(alice), depositAmount, "User should now have the Shares");
    }

    function test__Vault__WithdrawAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        SimpleUSDC(address(vaultParams.asset)).mint(vaultParams.custodian, 1 * precision);
        uint256 finalBalance = SimpleUSDC(address(vaultParams.asset)).balanceOf(vaultParams.custodian);

        vm.prank(vaultParams.custodian);
        vaultParams.asset.transfer(address(vault), finalBalance);

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = vaultParams.asset.balanceOf(alice);
        vm.startPrank(alice);
        vault.approve(address(vault), shares);
        uint256 assets = vault.redeem(shares, alice, alice);
        uint256 balanceAfterRedeem = vaultParams.asset.balanceOf(alice);
        vm.stopPrank();

        assertEq(balanceAfterRedeem, balanceBeforeRedeem + assets, "Alice should recieve finalBalance with 10% yeild");
    }

    function test__Vault__totalAssetShouldReturnTotalDeposited() public {
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        deposit(alice, depositAmount);

        assertEq(vault.totalAssets(), vault.totalAssetDeposited());
        assertEq(vault.totalAssetDeposited(), depositAmount);
    }

    function test__Vault__ShouldRevertOnTransferOutsideEcosystem() public {
        uint256 depositAmount = 100 * precision;
        deposit(alice, depositAmount);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Vault.CredbullVault__TransferOutsideEcosystem.selector, address(alice)));
        vault.transfer(bob, 100 * precision);
    }

    function test__Vault__ShouldRevertOnNativeTokenTransfer() public {
        vm.expectRevert(Vault.CredbullVault__TransferOutsideEcosystem.selector);
        (bool isReceivedSuccess,) = address(vault).call{ value: 5 wei }("");
        assertFalse(isReceivedSuccess, "Should fail: receive function is not allowed to accept Native tokens.");

        vm.expectRevert(Vault.CredbullVault__TransferOutsideEcosystem.selector);
        (bool isFallbackSuccess,) =
            address(vault).call{ value: 8 wei }(abi.encodeWithSignature("nonExistentFunction()"));
        assertFalse(isFallbackSuccess, "Should fail: fallback function is not allowed to accept Native tokens.");
    }

    function test__Vault__ShouldRevertOnFractionalDepositAmount_Fuzz(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1, 1e6 * 1e6);

        if ((depositAmount % precision) > 0) {
            depositWithRevert(alice, depositAmount);
        } else {
            deposit(alice, depositAmount);
        }
    }

    function test__ShouldRevertIfDecimalIsNotSupported() public {
        vm.expectRevert(abi.encodeWithSelector(Vault.CredbullVault__UnsupportedDecimalValue.selector, 24));
        vm.mockCall(address(vaultParams.asset), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(24));
        createTestVault(vaultParams);
    }

    function test__Vault__Deposit__Fuzz(uint256 depositAmount) public {
        uint256 custodiansBalance = vaultParams.asset.balanceOf(vaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User should start with no Shares");

        uint256 shares;
        (, uint256 remainder) = depositAmount.tryMod(precision);
        if (remainder > 0) {
            shares = depositWithRevert(alice, depositAmount);
        } else {
            // ---- Setup Part 2 - Alice Deposit and Receives shares ----
            //Call internal deposit function
            shares = deposit(alice, depositAmount);

            // ---- Assert - Vault gets the Assets, Alice gets Shares ----

            // Vault should have the assets
            assertEq(vault.totalAssets(), depositAmount, "Vault should now have the assets");
            assertEq(
                vaultParams.asset.balanceOf(vaultParams.custodian),
                depositAmount + custodiansBalance,
                "Custodian should have received the assets"
            );

            // Alice should have the shares
            assertEq(shares, depositAmount, "User should now have the Shares");
            assertEq(vault.balanceOf(alice), depositAmount, "User should now have the Shares");
        }
    }

    function test__Vault__MultiDepositAndWithdraw__Fuzz(uint256 aliceDepositAmount, uint256 bobDepositAmount) public {
        uint256 custodiansBalance = vaultParams.asset.balanceOf(vaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User A should start with no Shares");
        assertEq(vault.balanceOf(bob), 0, "User B should start with no Shares");

        uint256 aliceShares;
        uint256 bobShares;

        (, uint256 aliceRemainder) = aliceDepositAmount.tryMod(precision);
        (, uint256 bobRemainder) = bobDepositAmount.tryMod(precision);

        if (aliceRemainder > 0) {
            aliceShares = depositWithRevert(alice, aliceDepositAmount);
        } else {
            aliceShares = deposit(alice, aliceDepositAmount);
        }

        if (bobRemainder > 0) {
            bobShares = depositWithRevert(bob, bobDepositAmount);
        } else {
            bobShares = deposit(bob, bobDepositAmount);
        }

        uint256 totalDepositAmount;
        if (aliceShares > 0) {
            totalDepositAmount += aliceDepositAmount;
        }

        if (bobShares > 0) {
            totalDepositAmount += bobDepositAmount;
        }

        assertEq(vault.totalAssets(), totalDepositAmount, "Vault should now have the assets");

        assertEq(
            vaultParams.asset.balanceOf(vaultParams.custodian),
            totalDepositAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        assertEq(vault.balanceOf(alice), aliceShares, "Alice should now have the Shares");
        assertEq(vault.balanceOf(bob), bobShares, "Bob should now have the Shares");

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        SimpleUSDC(address(vaultParams.asset)).mint(
            vaultParams.custodian, totalDepositAmount.mulDiv(10_00, MAX_PERCENTAGE)
        );
        uint256 finalBalance = SimpleUSDC(address(vaultParams.asset)).balanceOf(vaultParams.custodian);

        vm.prank(vaultParams.custodian);
        vaultParams.asset.transfer(address(vault), finalBalance);

        if (aliceShares > 0) {
            // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
            uint256 vaultSupplyBeofreRedeem = vault.totalSupply();
            uint256 balanceBeforeRedeem = vaultParams.asset.balanceOf(alice);
            vm.startPrank(alice);
            vault.approve(address(vault), aliceShares);
            uint256 assets = vault.redeem(aliceShares, alice, alice);
            uint256 balanceAfterRedeem = vaultParams.asset.balanceOf(alice);
            vm.stopPrank();

            assertEq(
                balanceAfterRedeem, balanceBeforeRedeem + assets, "Alice should recieve finalBalance with 10% yeild"
            );
            assertEq(vault.totalSupply(), vaultSupplyBeofreRedeem - assets, "Vault should burn Alice's shares");
        }

        if (bobShares > 0) {
            // ---- Assert Vault burns shares and Bob receive asset with additional 10% ---
            uint256 vaultSupplyBeofreRedeem = vault.totalSupply();
            uint256 balanceBeforeRedeem = vaultParams.asset.balanceOf(bob);
            vm.startPrank(bob);
            vault.approve(address(vault), bobShares);
            uint256 assets = vault.redeem(bobShares, bob, bob);
            uint256 balanceAfterRedeem = vaultParams.asset.balanceOf(bob);
            vm.stopPrank();

            assertEq(balanceAfterRedeem, balanceBeforeRedeem + assets, "Bob should recieve finalBalance with 10% yeild");
            assertEq(vault.totalSupply(), vaultSupplyBeofreRedeem - assets, "Vault should burn Bob's shares");
        }
    }

    function test__BaseVault__WithdrawOnBehalfOf() public {
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        SimpleUSDC(address(vaultParams.asset)).mint(vaultParams.custodian, depositAmount.mulDiv(10_00, MAX_PERCENTAGE));
        uint256 finalBalance = SimpleUSDC(address(vaultParams.asset)).balanceOf(vaultParams.custodian);

        vm.prank(vaultParams.custodian);
        vaultParams.asset.transfer(address(vault), finalBalance);

        // ---- Assert Vault burns shares
        vm.startPrank(alice);
        vault.approve(address(vault), shares);
        vault.approve(address(this), shares);
        vm.stopPrank();

        vault.redeem(shares, alice, alice);
    }

    function test__BaseVault__WithdrawERC20() public {
        SimpleUSDC mock1 = new SimpleUSDC(100 * precision);
        SimpleUSDC mock2 = new SimpleUSDC(100 * precision);

        mock1.mint(address(vault), 100 * precision);
        mock2.mint(address(vault), 100 * precision);

        address[] memory tokens = new address[](2);
        tokens[0] = address(mock1);
        tokens[1] = address(mock2);

        vault.withdrawERC20(tokens, alice);

        assertEq(mock1.balanceOf(alice), 100 * precision);
        assertEq(mock2.balanceOf(alice), 100 * precision);
    }

    function test__BaseVault__ShouldRevertOnSendingETHToVault() public {
        (bool isReceivedSuccess,) = address(vault).call{ value: 5 wei }("");
        assertFalse(isReceivedSuccess, "Should fail: receive function is not allowed to accept Native tokens.");

        (bool isFallbackSuccess,) =
            address(vault).call{ value: 8 wei }(abi.encodeWithSignature("nonExistentFunction()"));
        assertFalse(isFallbackSuccess, "Should fail: fallback function is not allowed to accept Native tokens.");
    }

    function test__BaseVault__ShouldRevertAllTransfers() public {
        vm.expectRevert(abi.encodeWithSelector(Vault.CredbullVault__TransferOutsideEcosystem.selector, address(alice)));
        vm.prank(alice);
        vault.transfer(bob, 100 * precision);

        vm.expectRevert(abi.encodeWithSelector(Vault.CredbullVault__TransferOutsideEcosystem.selector, alice));
        vm.prank(alice);
        vault.transferFrom(alice, bob, 100 * precision);
    }

    function deposit(address user, uint256 assets) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }

    function depositWithRevert(address user, uint256 assets) internal returns (uint256 shares) {
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);
        vm.expectRevert(abi.encodeWithSelector(Vault.CredbullVault__InvalidAssetAmount.selector, assets));
        shares = vault.deposit(assets, alice);
        vm.stopPrank();
    }

    function createTestVault(Vault.VaultParams memory _vaultParams) internal returns (SimpleVault) {
        return new SimpleVault(_vaultParams);
    }
}
