// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVaultTestBase } from "@test/test/token/ERC1155/IMultiTokenVaultTestBase.t.sol";

contract IMTVTestParamArray {
    IMultiTokenVaultTestBase.TestParam[] internal _allTestParams;

    // Function to add testParams to the array
    function addTestParam(IMultiTokenVaultTestBase.TestParam memory testParam) public {
        _allTestParams.push(testParam);
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

            _allTestParams.push(testParamsWithOffset); // Add the generated params with offset
        }
    }

    // Function to return the length of the array
    function length() public view returns (uint256) {
        return _allTestParams.length;
    }

    function get(uint256 index) public view returns (IMultiTokenVaultTestBase.TestParam memory testParam) {
        return _allTestParams[index];
    }

    function getAll() public view returns (IMultiTokenVaultTestBase.TestParam[] memory testParamArr) {
        return _allTestParams;
    }

    function getAllDepositPeriods() public view returns (uint256[] memory depositPeriods_) {
        uint256[] memory depositPeriods = new uint256[](_allTestParams.length);

        for (uint256 i = 0; i < _allTestParams.length; i++) {
            depositPeriods[i] = _allTestParams[i].depositPeriod;
        }

        return depositPeriods;
    }

    function accountArray(address account, uint256 size) public pure returns (address[] memory accounts_) {
        address[] memory accounts = new address[](size);

        for (uint256 i = 0; i < size; i++) {
            accounts[i] = account;
        }

        return accounts;
    }
}
