// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVaultTestBase } from "@test/test/token/ERC1155/IMultiTokenVaultTestBase.t.sol";

contract IMTVTestParams {
    IMultiTokenVaultTestBase.TestParam[] private _all;

    // Function to add testParams to the array
    function add(IMultiTokenVaultTestBase.TestParam memory testParam) public {
        _all.push(testParam);
    }

    // Function to generate and add multiple testParams with offsets
    function initUsingOffsets(IMultiTokenVaultTestBase.TestParam memory testParam) public {
        uint256[6] memory offsetNumPeriodsArr =
            [0, 1, 2, testParam.redeemPeriod - 1, testParam.redeemPeriod, testParam.redeemPeriod + 1];

        for (uint256 i = 0; i < offsetNumPeriodsArr.length; i++) {
            uint256 offsetNumPeriods = offsetNumPeriodsArr[i];

            IMultiTokenVaultTestBase.TestParam memory testParamsWithOffset = IMultiTokenVaultTestBase.TestParam({
                principal: testParam.principal,
                depositPeriod: testParam.depositPeriod + offsetNumPeriods,
                redeemPeriod: testParam.redeemPeriod + offsetNumPeriods
            });

            _all.push(testParamsWithOffset); // Add the generated params with offset
        }
    }

    // Function to return the length of the array
    function length() public view returns (uint256) {
        return _all.length;
    }

    function get(uint256 index) public view returns (IMultiTokenVaultTestBase.TestParam memory testParam) {
        return _all[index];
    }

    function set(uint256 index, uint256 principal) public {
        _all[index].principal = principal;
    }

    function all() public view returns (IMultiTokenVaultTestBase.TestParam[] memory testParamArr) {
        return _all;
    }

    function totalPrincipal() public view returns (uint256 totalPrincipal_) {
        uint256 principal = 0;
        for (uint256 i = 0; i < _all.length; i++) {
            principal += _all[i].principal;
        }
        return principal;
    }

    function deposits() public view returns (uint256[] memory depositPeriods_, uint256[] memory principals_) {
        uint256 length_ = _all.length;

        uint256[] memory _depositPeriods = new uint256[](length_);
        uint256[] memory _principals = new uint256[](length_);

        for (uint256 i = 0; i < length_; i++) {
            _depositPeriods[i] = _all[i].depositPeriod;
            _principals[i] = _all[i].principal;
        }

        return (_depositPeriods, _principals);
    }

    function depositPeriods() public view returns (uint256[] memory depositPeriods_) {
        (depositPeriods_,) = deposits();
        return depositPeriods_;
    }

    function principals() public view returns (uint256[] memory principals_) {
        (, principals_) = deposits();
        return principals_;
    }

    function accountArray(address account) public view returns (address[] memory accounts_) {
        address[] memory accounts = new address[](_all.length);

        for (uint256 i = 0; i < _all.length; i++) {
            accounts[i] = account;
        }

        return accounts;
    }
}
