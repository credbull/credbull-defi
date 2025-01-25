// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

contract TestParamFactory {
    uint256 public immutable _TENOR;
    uint256 public immutable _SCALE;

    uint256 public _basePrincipal;
    uint256 public _testCount;

    constructor(uint256 tenor, uint256 scale) {
        _TENOR = tenor;
        _SCALE = scale;

        _basePrincipal = 100 * _SCALE;
    }

    function create(uint256 depositPeriod, uint256 redeemPeriod)
        public
        returns (TestParamSet.TestParam memory testParam)
    {
        uint256 principal = _basePrincipal + _testCount++;

        return
            TestParamSet.TestParam({ principal: principal, depositPeriod: depositPeriod, redeemPeriod: redeemPeriod });
    }

    // Predefined scenarios with depositOnX convention
    function depositOnZeroRedeemPreTenor() public returns (TestParamSet.TestParam memory) {
        return create(0, _TENOR - 1);
    }

    function depositOnZeroRedeemOnTenor() public returns (TestParamSet.TestParam memory) {
        return create(0, _TENOR);
    }

    function depositOnZeroRedeemPostTenor() public returns (TestParamSet.TestParam memory) {
        return create(0, _TENOR + 1);
    }

    function depositOnOneRedeemPreTenor() public returns (TestParamSet.TestParam memory) {
        return create(1, _TENOR - 1);
    }

    function depositOnOneRedeemOnTenor() public returns (TestParamSet.TestParam memory) {
        return create(1, _TENOR);
    }

    function depositOnOneRedeemPostTenor() public returns (TestParamSet.TestParam memory) {
        return create(1, _TENOR + 1);
    }

    function depositPreTenorRedeemPreTenor() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR - 1, _TENOR - 1);
    }

    function depositPreTenorRedeemOnTenor() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR - 1, _TENOR);
    }

    function depositPreTenorRedeemPostTenor() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR - 1, _TENOR + 1);
    }

    function depositOnTenorRedeemPreTenor2() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR, (2 * _TENOR - 1));
    }

    function depositOnTenorRedeemOnTenor2() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR, (2 * _TENOR));
    }

    function depositOnTenorRedeemPostTenor2() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR, (2 * _TENOR + 1));
    }

    function depositPostTenorRedeemPreTenor2() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR + 1, (2 * _TENOR - 1));
    }

    function depositPostTenorRedeemOnTenor2() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR + 1, (2 * _TENOR));
    }

    function depositPostTenorRedeemPostTenor2() public returns (TestParamSet.TestParam memory) {
        return create(_TENOR + 1, (2 * _TENOR + 1));
    }
}
