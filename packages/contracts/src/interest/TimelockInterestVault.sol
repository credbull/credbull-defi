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

contract TimelockInterestVault is TimelockIERC1155, DiscountingVault, Pausable, IProduct {
    constructor(DiscountingVaultParams memory params, address initialOwner)
        DiscountingVault(params)
        TimelockIERC1155(initialOwner)
    { }

    // we want the supply of the ERC20 token - not the locks
    function totalSupply() public view virtual override(ERC1155Supply, IERC20, ERC20) returns (uint256) {
        return ERC20.totalSupply();
    }

    function deposit(uint256 assets, address receiver)
        public
        override(IProduct, MultiTokenVault)
        whenNotPaused
        returns (uint256 shares)
    {
        shares = MultiTokenVault.deposit(assets, receiver);

        // Call the internal _lock function instead, which handles the locking logic
        _lockInternal(receiver, currentTimePeriodsElapsed + TENOR, shares);

        return shares;
    }

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

    /**
     * @dev See {IMultiTokenVault-redeemForDepositPeriod}
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) public override returns (uint256 assets) {
        _unlockInternal(owner, currentTimePeriodsElapsed, shares);

        uint256 _assets = MultiTokenVault.redeemForDepositPeriod(shares, receiver, owner, depositPeriod, redeemPeriod);

        return _assets;
    }

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

    /**
     * @notice Rolls over a specified amount of unlocked tokens for a new lock period.
     * @param account The address of the account whose tokens are to be rolled over.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @param value The amount of tokens to be rolled over.
     */
    function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value) public override onlyOwner {
        uint256 sharesForNextPeriod = previewConvertSharesForRollover(account, lockReleasePeriod, value);
        uint256 impliedDepositPeriod = (currentTimePeriodsElapsed - TENOR);

        // TODO: this probably only makes sense if lockReleasePeriod == currentTimePeriodsElapsed.  assert as such.

        // case where the Shares[P1] for first period are LESS than Shares[P2], e.g. due to Rollover Bonus
        if (sharesForNextPeriod > value) {
            uint256 deficientValue = sharesForNextPeriod - value;

            TimelockIERC1155._lockInternal(account, currentTimePeriodsElapsed, deficientValue); // mint from ERC1155 (Timelock)
            ERC20._mint(account, deficientValue); // mint from ER20/ERC4626 (Vault)
            DEPOSITS.mint(account, impliedDepositPeriod, deficientValue, ""); // mint from ER20/ERC4626 (Deposit Ledger)
        }

        // case where the Shares[P1] for first period are GREATER than Shares[P2], e.g. due to Discounting
        if (value > sharesForNextPeriod) {
            uint256 excessValue = value - sharesForNextPeriod;

            ERC1155._burn(account, lockReleasePeriod, excessValue); // burn from ERC1155 (Timelock)

            ERC20._burn(account, excessValue); // burn from ERC20/ERC4626 (Vault)
            DEPOSITS.burn(account, impliedDepositPeriod, excessValue); // burn from ER20/ERC4626 (Deposit Ledger)
        }

        // now move the shares to the new period
        DEPOSITS.burn(account, impliedDepositPeriod, sharesForNextPeriod);
        DEPOSITS.mint(account, currentTimePeriodsElapsed, sharesForNextPeriod, "");

        TimelockIERC1155.rolloverUnlocked(account, lockReleasePeriod, sharesForNextPeriod);
    }

    function calcRolloverBonus(address, /* account */ uint256, /* lockReleasePeriod */ uint256 value)
        public
        view
        returns (uint256 rolloverBonus)
    {
        return CalcSimpleInterest.calcInterest(value, 1, TENOR, FREQUENCY);
    }

    /**
     *  When rolloing over, we need to re-calculate the shares to account for the passage of time
     *  Any difference will need to be credited or debited from the current balance
     * NB - this does revert unlike ERC4626 preview meethods.
     */
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

        uint256 assetsForNextPeriod = principalAndYieldFirstPeriod + rolloverBonus;

        // shares for the next period is the Discounted PrincipalAndYield for the first Period + Rollover bonus
        uint256 _sharesForNextPeriod = convertToShares(assetsForNextPeriod); // discounted principal for rollover period

        return _sharesForNextPeriod;
    }

    function getLockDuration() public view override returns (uint256 lockDuration) {
        return TENOR;
    }

    // ================= Period and Periodable =================

    function getCurrentPeriod() public view virtual override returns (uint256 currentPeriod) {
        return currentTimePeriodsElapsed;
    }

    function setCurrentPeriod(uint256 _currentPeriod) public override {
        setCurrentTimePeriodsElapsed(_currentPeriod);
    }

    // ================= Pause =================

    function pause() public onlyOwner {
        Pausable._pause();
    }

    function unpause() public onlyOwner {
        Pausable._unpause();
    }

    /**
     * @notice Returns the interest accrued for this account for the given depositTimePeriod
     * e.g. if Alice deposits on Day 1 and Day 2, this will ONLY return the interest for the Day 1 deposit
     * @param account The address of the user.
     * @param depositTimePeriod The time period to calculate for
     * @return The amount of interest accrued by the user for the given depositTimePeriod
     */
    function calcInterestForDepositTimePeriod(address account, uint256 depositTimePeriod)
        public
        view
        override
        returns (uint256)
    {
        Principal memory principal = _createPrincipal(account, depositTimePeriod);

        uint256 principalAmount = principal.principalAmount;

        uint256 interest = calcYield(principalAmount, depositTimePeriod, currentTimePeriodsElapsed);

        return interest;
    }

    /**
     * @notice Returns the total interest accrued by a user across ALL deposit time periods
     * @param account The address of the user.
     * @return The total amount of interest earned by the user.
     */
    function calcTotalInterest(address account) public view override returns (uint256) {
        uint256[] memory userLockPeriods = getLockPeriods(account);
        Principal[] memory principals = _getPrincipalsForLockPeriods(account, userLockPeriods);

        uint256 totalInterest = 0;

        for (uint256 i = 0; i < principals.length; i++) {
            uint256 interest =
                calcYield(principals[i].principalAmount, principals[i].depositTimePeriod, currentTimePeriodsElapsed);

            totalInterest += interest;
        }

        return totalInterest;
    }

    /**
     * @notice Returns the total amount of assets deposited by a user.
     * @param account The address of the user.
     * @return The total amount of assets deposited by the user.
     */
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

    function _createPrincipal(address account, uint256 depositTimePeriod) internal view returns (Principal memory) {
        uint256 redeemTimePeriod = depositTimePeriod + TENOR;
        uint256 shares = balanceOf(account, redeemTimePeriod);

        uint256 principalAmount = _convertToPrincipalAtDepositPeriod(shares, depositTimePeriod);

        Principal memory principal =
            Principal({ account: account, principalAmount: principalAmount, depositTimePeriod: depositTimePeriod });

        return principal;
    }

    // =============== Utility ===============

    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed)
        public
        virtual
        override(IProduct, MultiTokenVault)
    {
        MultiTokenVault.setCurrentTimePeriodsElapsed(_currentTimePeriodsElapsed);
    }
}
