// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MultiTokenVault } from "@credbull/interest/MultiTokenVault.sol";
import { DiscountingVault } from "@credbull/interest/DiscountingVault.sol";
import { TimelockIERC1155 } from "@credbull/timelock/TimelockIERC1155.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { IProduct } from "@credbull/interest/IProduct.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title TimelockInterestVault
 * @dev A vault that locks tokens with interest calculations and supports token rollover.
 */
contract TimelockInterestVault is TimelockIERC1155, DiscountingVault, Pausable, IProduct {
    constructor(DiscountingVaultParams memory params, address initialOwner)
        DiscountingVault(params)
        TimelockIERC1155(initialOwner)
    { }

    /// @notice Returns the total supply of ERC20 tokens.
    function totalSupply() public view virtual override(ERC1155Supply, IERC20, ERC20) returns (uint256) {
        return ERC20.totalSupply();
    }

    /// @notice Deposits `assets` and locks shares for `receiver` for the current period + tenor.
    function deposit(uint256 assets, address receiver)
        public
        override(IProduct, MultiTokenVault)
        whenNotPaused
        returns (uint256 shares)
    {
        shares = MultiTokenVault.deposit(assets, receiver);
        _lockInternal(receiver, currentTimePeriodsElapsed + TENOR, shares);
        return shares;
    }

    /// @notice Redeems `shares` for assets at the current period, using the calculated deposit period.
    // TODO: this is unsafe, only holds when "depositPeriod = currentPeriod - TENOR"
    // TODO: deprecated, use redeemForDepositPeriod(...depositPeriod, redeemPeriod) instead
    function redeem(uint256 shares, address receiver, address owner)
        public
        override(IProduct, MultiTokenVault)
        whenNotPaused
        returns (uint256 assets)
    {
        uint256 depositPeriod = _getDepositPeriodFromRedeemPeriod(currentTimePeriodsElapsed);
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentTimePeriodsElapsed);
    }

    /// @notice Redeems `shares` for `receiver` and `owner` for `depositPeriod` and `redeemPeriod`.
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) public override returns (uint256 assets) {
        _unlockInternal(owner, currentTimePeriodsElapsed, shares);
        return MultiTokenVault.redeemForDepositPeriod(shares, receiver, owner, depositPeriod, redeemPeriod);
    }

    /// @notice Redeems `shares` for `receiver` and `owner` for `redeemPeriod`.
    // TODO: this is unsafe, only holds when "depositPeriod = currentPeriod - TENOR"
    // TODO: deprecated, use redeemForDepositPeriod(...depositPeriod, redeemPeriod) instead
    function redeemAtPeriod(uint256 shares, address receiver, address owner, uint256 redeemTimePeriod)
        public
        override
        returns (uint256 assets)
    {
        uint256 depositPeriod = _getDepositPeriodFromRedeemPeriod(currentTimePeriodsElapsed);

        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, redeemTimePeriod);
    }

    /// @notice Rolls over unlocked tokens for a new lock period.
    function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value) public override onlyOwner {
        uint256 sharesForNextPeriod = previewConvertSharesForRollover(account, lockReleasePeriod, value);
        uint256 impliedDepositPeriod = (currentTimePeriodsElapsed - TENOR);

        // TODO: this probably only makes sense if lockReleasePeriod == currentTimePeriodsElapsed.  assert as such.

        // case where the Shares[P1] for first period are LESS than Shares[P2], e.g. due to Rollover Bonus
        if (sharesForNextPeriod > value) {
            uint256 deficientValue = sharesForNextPeriod - value;

            TimelockIERC1155._lockInternal(account, currentTimePeriodsElapsed, deficientValue); // mint from ERC1155 (Timelock)
            ERC20._mint(account, deficientValue); // mint from ER20/ERC4626 (Vault)
            DEPOSITS.safeMint(account, impliedDepositPeriod, deficientValue, ""); // mint from ER20/ERC4626 (Deposit Ledger)
        }

        // case where the Shares[P1] for first period are GREATER than Shares[P2], e.g. due to Discounting
        if (value > sharesForNextPeriod) {
            uint256 excessValue = value - sharesForNextPeriod;

            ERC1155._burn(account, lockReleasePeriod, excessValue); // burn from ERC1155 (Timelock)

            ERC20._burn(account, excessValue); // burn from ERC20/ERC4626 (Vault)
            DEPOSITS.burn(account, impliedDepositPeriod, excessValue, _emptyBytesArray()); // burn from ER20/ERC4626 (Deposit Ledger)
        }

        // now move the shares to the new period
        DEPOSITS.burn(account, impliedDepositPeriod, sharesForNextPeriod, _emptyBytesArray());
        DEPOSITS.safeMint(account, currentTimePeriodsElapsed, sharesForNextPeriod, "");

        TimelockIERC1155.rolloverUnlocked(account, lockReleasePeriod, sharesForNextPeriod);
    }

    /// @notice Returns the rollover bonus for `value` at `lockReleasePeriod`.
    function calcRolloverBonus(address, /* account */ uint256, /* lockReleasePeriod */ uint256 value)
        public
        view
        returns (uint256 rolloverBonus)
    {
        uint256 rolloverBonusAPY = 1 * SCALE;
        return CalcSimpleInterest.calcInterest(value, rolloverBonusAPY, TENOR, FREQUENCY, SCALE);
    }

    /// @notice Previews the converted shares for rolling over tokens.
    function previewConvertSharesForRollover(address account, uint256 lockReleasePeriod, uint256 value)
        public
        view
        returns (uint256 sharesForNextPeriod)
    {
        uint256 unlockableAmount = this.previewUnlock(account, lockReleasePeriod);

        // Ensure that the account has enough unlockable tokens to roll over
        if (value > unlockableAmount) {
            revert InsufficientLockedBalanceAtPeriod(account, unlockableAmount, value, lockReleasePeriod);
        }

        uint256 principalAndYieldFirstPeriod = _convertToAssetsForImpliedDepositPeriod(value, lockReleasePeriod); // principal + first period interest

        uint256 rolloverBonus = calcRolloverBonus(account, lockReleasePeriod, principalAndYieldFirstPeriod); // bonus for rolled over assets

        return convertToShares(principalAndYieldFirstPeriod + rolloverBonus); // discounted principal for rollover period
    }

    /// @notice Returns the lock duration.
    function getLockDuration() public view override returns (uint256 lockDuration) {
        return TENOR;
    }

    // ================= Period =================

    /// @notice Returns the current period.
    function getCurrentPeriod() public view virtual override returns (uint256 currentPeriod) {
        return currentTimePeriodsElapsed;
    }

    /// @notice Sets the current period.
    function setCurrentPeriod(uint256 currentPeriod_) public override {
        setCurrentTimePeriodsElapsed(currentPeriod_);
    }

    // ================= Pause =================

    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        Pausable._pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        Pausable._unpause();
    }

    /// @notice Returns the interest accrued for `account` during `depositTimePeriod`.
    function calcInterestForDepositTimePeriod(address account, uint256 depositTimePeriod)
        public
        view
        override
        returns (uint256)
    {
        Principal memory principal = _createPrincipal(account, depositTimePeriod);
        uint256 interest = calcYield(principal.principalAmount, depositTimePeriod, currentTimePeriodsElapsed);
        return interest;
    }

    /// @notice Returns the total interest accrued by `account` across all deposit periods.
    function calcTotalInterest(address account) public view override returns (uint256) {
        uint256[] memory userLockPeriods = getLockPeriods(account);
        Principal[] memory principals = _getPrincipalsForLockPeriods(account, userLockPeriods);
        uint256 totalInterest = 0;
        for (uint256 i = 0; i < principals.length; i++) {
            totalInterest +=
                calcYield(principals[i].principalAmount, principals[i].depositTimePeriod, currentTimePeriodsElapsed);
        }
        return totalInterest;
    }

    /// @notice Returns the total deposits by `account`.
    function calcTotalDeposits(address account) public view override returns (uint256) {
        uint256[] memory userLockPeriods = getLockPeriods(account);

        // get the principal amounts for each lock period
        Principal[] memory principals = _getPrincipalsForLockPeriods(account, userLockPeriods);
        uint256 totalDeposit = 0;

        // Sum up all the principal amounts
        for (uint256 i = 0; i < principals.length; i++) {
            totalDeposit += principals[i].principalAmount;
        }
        return totalDeposit;
    }

    struct Principal {
        address account;
        uint256 principalAmount;
        uint256 depositTimePeriod;
    }

    /// @notice Returns the principals for `account` based on lock periods.
    function _getPrincipalsForLockPeriods(address account, uint256[] memory lockPeriods)
        internal
        view
        returns (Principal[] memory)
    {
        Principal[] memory principals = new Principal[](lockPeriods.length);

        // Iterate through the lock periods and calculate the principal for each
        for (uint256 i = 0; i < lockPeriods.length; i++) {
            uint256 redeemPeriod = lockPeriods[i];

            Principal memory principal = _createPrincipal(account, redeemPeriod - TENOR);

            // Store the principal in the array
            principals[i] = principal;
        }
        return principals;
    }

    /// @dev Creates and returns a Principal object for `account` and `depositTimePeriod`.
    function _createPrincipal(address account, uint256 depositTimePeriod) internal view returns (Principal memory) {
        uint256 redeemTimePeriod = depositTimePeriod + TENOR;
        uint256 shares = balanceOf(account, redeemTimePeriod);

        uint256 principalAmount = _convertToPrincipalAtDepositPeriod(shares, depositTimePeriod);

        Principal memory principal =
            Principal({ account: account, principalAmount: principalAmount, depositTimePeriod: depositTimePeriod });

        return principal;
    }

    // =============== Utility ===============

    /// @notice Sets the current number of periods elapsed.
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed)
        public
        virtual
        override(IProduct, MultiTokenVault)
    {
        MultiTokenVault.setCurrentTimePeriodsElapsed(currentTimePeriodsElapsed);
    }
}
