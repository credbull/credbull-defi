// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { PureStone } from "@credbull/yield/PureStone.sol";
import { DiscountVault } from "@credbull/token/ERC4626/DiscountVault.sol";
import { CalcDiscounted } from "@credbull/yield/CalcDiscounted.sol";

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { SimpleInterestYieldStrategy } from "@credbull/yield/strategy/SimpleInterestYieldStrategy.sol";
import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { IVaultVerifierBase } from "@test/test/token/ERC4626/IVaultVerifierBase.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

contract PureStoneTest is IVaultVerifierBase {
    using TestParamSet for TestParamSet.TestParam[];

    IERC20Metadata internal _asset;
    IYieldStrategy private _yieldStrategy;
    uint256 internal _scale;

    TestParamSet.TestParam internal _testParams1;

    function setUp() public virtual {
        vm.prank(_owner);
        _asset = new SimpleUSDC(_owner, 1_000_000 ether);
        _yieldStrategy = new SimpleInterestYieldStrategy();

        _scale = 10 ** _asset.decimals();
        _transferAndAssert(_asset, _owner, _alice, 100_000 * _scale);
        _testParams1 = TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 10, redeemPeriod: 40 });
    }

    function test__MultiTokenVaultTest__DepositAndRedeem() public {
        uint256 assetToSharesRatio = 3;

        _transferAndAssert(_asset, _owner, _charlie, 100_000 * _scale);

        PureStone vault = _createPureStone(_asset, assetToSharesRatio, 10);

        verifyVaultAtOffsets(_charlie, vault, _testParams1);
    }

    function _createPureStone(IERC20Metadata asset_, uint256, /* assetToSharesRatio */ uint256 yieldPercentage)
        internal
        virtual
        returns (PureStone)
    {
        DiscountVault.DiscountVaultParams memory params = DiscountVault.DiscountVaultParams({
            asset: asset_,
            yieldStrategy: _yieldStrategy,
            ratePercentageScaled: yieldPercentage * _scale,
            frequency: 360,
            vaultStartTimestamp: 0,
            tenor: 30
        });

        PureStone vaultImpl = new PureStone();
        PureStone vaultProxy = PureStone(
            address(new ERC1967Proxy(address(vaultImpl), abi.encodeWithSelector(vaultImpl.initialize.selector, params)))
        );

        IYieldStrategy vaultYieldStrategy = vaultProxy._yieldStrategy();
        assertEq(0, vaultYieldStrategy.calcYield(address(vaultProxy), 1, 0, 10));

        return vaultProxy;
    }

    /// @dev expected shares.  how much in assets should this vault give for the the deposit.
    function _expectedShares(IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        override
        returns (uint256 expectedShares)
    {
        PureStone pureStone = PureStone(address(vault));

        return CalcDiscounted.calcDiscounted(testParam.principal, pureStone.price(), _scale);
    }

    function _expectedReturns(uint256, /* shares */ IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        override
        returns (uint256 expectedReturns_)
    {
        PureStone pureStone = PureStone(address(vault));

        if (testParam.redeemPeriod == testParam.depositPeriod + pureStone._tenor()) {
            return pureStone.calcYieldSingleTenor(testParam.principal);
        } else {
            return 0; // TODO - expected returns are more complicated than this.
        }
    }

    /// @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
    // // TODO - set(remove) the max allowance for the operator
    function _approveForAll(IVault vault, address owner, address operator, bool approved) internal virtual override {
        PureStone pureStone = PureStone(address(vault));

        uint256 balanceToApprove = approved ? pureStone.balanceOf(owner) : 0;

        vm.prank(owner);
        pureStone.approve(operator, balanceToApprove);
    }

    function _warpToPeriod(IVault vault, uint256 timePeriod) public virtual override {
        DiscountVault discountVault = DiscountVault(address(vault));

        uint256 warpToTimeInSeconds = discountVault._vaultStartTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }
}
