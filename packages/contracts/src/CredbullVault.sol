// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { console2 } from "forge-std/console2.sol";
import "../test/mocks/AKYCProvider.sol";
import { NetworkConfig } from "../script/HelperConfig.s.sol";

// Vaults exchange Assets for Shares in the Vault
// see: https://eips.ethereum.org/EIPS/eip-4626
contract CredbullVault is ERC4626, Ownable {
    using Math for uint256;

    //Error to revert on withdraw if vault is not matured
    error CredbullVault__NotMatured();
    //Error to revert mature if there is not enough balance to mature
    error CredbullVault__NotEnoughBalanceToMature();
    //Error to revert deposit if the valut is not opened yet
    error CredbullVault__VaultNotOpened();
    //Error to revert if the address is not whitelisted
    error CredbullVault__NotAWhitelistedAddress();

    //Address of the custodian to receive the assets on deposit and mint
    address public custodian;

    //Mock kyc provider
    AKYCProvider public kycProvider;

    /**
     * @dev
     * The assets deposited to the vault will be sent to custodian address so this is
     * separate variable to track the total assets that's been deposited to this vault.
     */
    uint256 private _totalAssetDeposited;

    /**
     * @dev
     * The fixed yield that's promised to the users on deposit.
     */
    uint256 private _fixedYield;

    /**
     * @dev
     * The timestamp when the vault opens for deposit.
     */
    uint256 public opensAtTimestamp;

    /**
     * @dev
     * The timestamp when the vault closes for deposit.
     */
    uint256 public closesAtTimestamp;

    /**
     * @notice - Track if vault is matured
     */
    bool public isMatured;

    struct Rules {
        bool checkMaturity;
        bool checkVaultOpenStatus;
        bool checkWhitelist;
    }

    Rules private rules;

    /**
     * @notice - Modifier to check for maturity status.
     * @dev - Used on internal withdraw method to check for maturity status
     */
    modifier onlyAfterMaturity() {
        if (rules.checkMaturity && !isMatured) {
            revert CredbullVault__NotMatured();
        }

        _;
    }

    /**
     * @notice - Modifier to check for vault open status.
     * @dev - Used on internal deposit method to check for open status
     */
    modifier onlyWhenOpened() {
        if (rules.checkVaultOpenStatus && (block.timestamp < opensAtTimestamp)) {
            revert CredbullVault__VaultNotOpened();
        }
        _;
    }

    /**
     * @notice - Modifier to check for whitelist status of an address
     */
    modifier onlyWhitelistAddress(address receiver) {
        if (rules.checkWhitelist && !kycProvider.status(receiver)) {
            revert CredbullVault__NotAWhitelistedAddress();
        }

        _;
    }

    constructor(
        NetworkConfig memory config,
        IERC20 asset,
        uint256 _promisedYield,
        uint256 _opensAtTimestamp,
        uint256 _closesAtTimestamp
    ) ERC4626(asset) ERC20(config.shareName, config.shareSymbol) Ownable(config.owner) {
        custodian = config.custodian;
        kycProvider = AKYCProvider(config.kycProvider);
        _fixedYield = _promisedYield;
        opensAtTimestamp = _opensAtTimestamp;
        closesAtTimestamp = _closesAtTimestamp;
    }

    /**
     * @dev - The internal deposit function of ERC4626 overridden to transfer the asset to custodian wallet
     * and update the _totalAssetDeposited on deposit/mint
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        override
        onlyWhenOpened
        onlyWhitelistAddress(receiver)
    {
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, custodian, assets);
        _totalAssetDeposited += assets;

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev - The internal withdraw function of ERC4626 overridden to update the _totalAssetDeposited on withdraw/redeem
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
        onlyAfterMaturity
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);
        _totalAssetDeposited -= assets;

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice - Returns the total assets deposited into the vault
     * @dev - The function is overridden to return the _totalAssetDeposited value to calculate shares.
     */
    function totalAssets() public view override returns (uint256) {
        return _totalAssetDeposited;
    }

    /**
     * @notice - Returns expected assets on maturity
     */
    function expectedAssetsOnMaturity() public view returns (uint256) {
        return _totalAssetDeposited.mulDiv(100 + _fixedYield, 100);
    }

    /**
     * @notice - mature method to mature the vault after the assets that was deposited from the custodian wallet with addition yield earned.
     * @dev - _totalAssetDeposited to be updated to calculate the right amount of asset with yield in proportion to the shares received.
     */
    function mature() external onlyOwner {
        uint256 currentBalance = IERC20(asset()).balanceOf(address(this));

        if (this.expectedAssetsOnMaturity() > currentBalance) {
            revert CredbullVault__NotEnoughBalanceToMature();
        }

        _totalAssetDeposited = currentBalance;
        isMatured = true;
    }

    /**
     * @notice - Function to update the value of the rules
     *
     * @param _rules - The rules to be updated
     */
    function setRules(Rules calldata _rules) external onlyOwner {
        rules = _rules;
    }
}
