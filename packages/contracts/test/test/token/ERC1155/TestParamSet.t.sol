// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TestParamSet {
    struct TestParam {
        uint256 principal;
        uint256 depositPeriod;
        uint256 redeemPeriod;
    }

    using TestParamSet for TestParam[];

    // Generate and add multiple testParams with offsets
    function toOffsetArray(TestParam memory testParam)
        internal
        pure
        returns (TestParam[] memory testParamsWithOffsets_)
    {
        uint256[6] memory offsetNumPeriodsArr =
            [0, 1, 2, testParam.redeemPeriod - 1, testParam.redeemPeriod, testParam.redeemPeriod + 1];

        TestParam[] memory testParamsWithOffsets = new TestParam[](offsetNumPeriodsArr.length);

        for (uint256 i = 0; i < offsetNumPeriodsArr.length; i++) {
            uint256 offsetNumPeriods = offsetNumPeriodsArr[i];

            TestParam memory testParamsWithOffset = TestParam({
                principal: testParam.principal,
                depositPeriod: testParam.depositPeriod + offsetNumPeriods,
                redeemPeriod: testParam.redeemPeriod + offsetNumPeriods
            });

            testParamsWithOffsets[i] = testParamsWithOffset;
        }

        return testParamsWithOffsets;
    }

    // Calculate the total principal across all TestParams
    function latestRedeemPeriod(TestParam[] memory self) internal pure returns (uint256 latestRedeemPeriod_) {
        uint256 _latestRedeemPeriod = 0;
        for (uint256 i = 0; i < self.length; i++) {
            uint256 redeemPeriod = self[i].redeemPeriod;
            if (_latestRedeemPeriod == 0 || redeemPeriod > _latestRedeemPeriod) {
                _latestRedeemPeriod = redeemPeriod;
            }
        }
        return _latestRedeemPeriod;
    }

    // Calculate the total principal across all TestParams
    function totalPrincipal(TestParam[] memory self) internal pure returns (uint256 totalPrincipal_) {
        uint256 principal = 0;
        for (uint256 i = 0; i < self.length; i++) {
            principal += self[i].principal;
        }
        return principal;
    }

    // Get deposit periods and principals in separate arrays
    function deposits(TestParam[] memory self)
        internal
        pure
        returns (uint256[] memory depositPeriods_, uint256[] memory principals_)
    {
        uint256 length_ = self.length;
        depositPeriods_ = new uint256[](length_);
        principals_ = new uint256[](length_);

        for (uint256 i = 0; i < length_; i++) {
            depositPeriods_[i] = self[i].depositPeriod;
            principals_[i] = self[i].principal;
        }

        return (depositPeriods_, principals_);
    }

    // Get only the deposit periods from all TestParams
    function depositPeriods(TestParam[] memory self) internal pure returns (uint256[] memory depositPeriods_) {
        (depositPeriods_,) = self.deposits();
        return depositPeriods_;
    }

    // Get only the principals from all TestParams
    function principals(TestParam[] memory self) internal pure returns (uint256[] memory principals_) {
        (, principals_) = self.deposits();
        return principals_;
    }

    // Generate an array of identical accounts associated with each TestParam
    function accountArray(TestParam[] memory self, address account)
        internal
        pure
        returns (address[] memory accounts_)
    {
        address[] memory accounts = new address[](self.length);

        for (uint256 i = 0; i < self.length; i++) {
            accounts[i] = account;
        }

        return accounts;
    }

    function _subset(TestParam[] memory origTestParams, uint256 from, uint256 to)
        public
        pure
        returns (TestParam[] memory newTestParams_)
    {
        newTestParams_ = new TestParam[](to - from + 1);

        uint256 arrayIndex = 0;
        for (uint256 i = from; i <= to; i++) {
            newTestParams_[arrayIndex] = origTestParams[i]; // Copy elements from original array
            arrayIndex++;
        }
        return newTestParams_;
    }

    function _splitBefore(TestParam[] memory origTestParams, uint256 splitBefore)
        public
        pure
        returns (TestParam[] memory leftSet_, TestParam[] memory rightSet_)
    {
        assert(splitBefore <= origTestParams.length);

        // Initialize leftSet and rightSet arrays with their respective sizes
        TestParam[] memory leftSet = new TestParam[](splitBefore); // Elements before splitBefore
        TestParam[] memory rightSet = new TestParam[](origTestParams.length - splitBefore); // Elements from splitBefore onwards

        // Copy elements to leftSet (up to splitBefore, exclusive)
        for (uint256 i = 0; i < splitBefore; i++) {
            leftSet[i] = origTestParams[i];
        }

        // Copy elements to rightSet (starting from splitBefore)
        for (uint256 i = splitBefore; i < origTestParams.length; i++) {
            rightSet[i - splitBefore] = origTestParams[i];
        }

        return (leftSet, rightSet);
    }
}
