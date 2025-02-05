// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TestParamSet {
    using TestParamSet for TestParam[];

    // Define a custom error for invalid split conditions
    error TestParamSet__InvalidSplit(uint256 splitBefore, uint256 paramsLength);

    // params for testing deposits and redeems
    struct TestParam {
        uint256 principal;
        uint256 depositPeriod;
        uint256 redeemPeriod;
    }

    // users involved in deposit and redeems.  using "tokenOwner" to distinguish vs. contract "owner"
    struct TestUsers {
        address tokenOwner; // owns tokens, can specify who can receive tokens
        address tokenReceiver; // token owner or granted tokens by the token owner
        address tokenOperator; // for txn to succeed MUST be tokenOwner or granted allowance by tokenOwner
    }

    // Generate and add multiple testParams with offsets
    function toOffsetArray(TestParam memory testParam)
        internal
        pure
        returns (TestParam[] memory testParamsWithOffsets_)
    {
        uint256[6] memory offsetAmounts =
            [0, 1, 2, testParam.redeemPeriod - 1, testParam.redeemPeriod, testParam.redeemPeriod + 1];

        TestParam[] memory testParamsWithOffsets = new TestParam[](offsetAmounts.length);

        for (uint256 i = 0; i < offsetAmounts.length; i++) {
            uint256 offsetAmount = offsetAmounts[i];

            TestParam memory testParamsWithOffset = TestParam({
                principal: testParam.principal * (1 + offsetAmount),
                depositPeriod: testParam.depositPeriod + offsetAmount,
                redeemPeriod: testParam.redeemPeriod + offsetAmount
            });

            testParamsWithOffsets[i] = testParamsWithOffset;
        }

        return testParamsWithOffsets;
    }

    // Generate and add multiple testParams with offsets
    function toSingletonArray(TestParam memory testParam) internal pure returns (TestParam[] memory testParamArray_) {
        TestParam[] memory array = new TestParam[](1);
        array[0] = testParam;
        return array;
    }

    // Generate and add multiple testParams with offsets
    function toLoadSet(uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        internal
        pure
        returns (TestParam[] memory loadTestParams_)
    {
        TestParam[] memory loadTestParams = new TestParam[](toPeriod - fromPeriod);

        uint256 arrayIndex = 0;
        for (uint256 i = fromPeriod; i < toPeriod; ++i) {
            loadTestParams[arrayIndex] =
                TestParamSet.TestParam({ principal: principal, depositPeriod: i, redeemPeriod: toPeriod });
            arrayIndex++;
        }

        return loadTestParams;
    }

    // simple scenario with only one user
    function toSingletonUsers(address account) internal pure returns (TestUsers memory testUsers_) {
        TestUsers memory testUsers = TestUsers({
            tokenOwner: account, // owns tokens, can specify who can receive tokens
            tokenReceiver: account, // receiver of tokens from the tokenOwner
            tokenOperator: account // granted allowance by tokenOwner to act on their behalf
         });

        return testUsers;
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

    // Get deposit periods and principals in separate arrays
    function redeems(TestParam[] memory self)
        internal
        pure
        returns (uint256[] memory redeemPeriods_, uint256[] memory principals_)
    {
        uint256 length_ = self.length;
        redeemPeriods_ = new uint256[](length_);
        principals_ = new uint256[](length_);

        for (uint256 i = 0; i < length_; i++) {
            redeemPeriods_[i] = self[i].redeemPeriod;
            principals_[i] = self[i].principal;
        }

        return (redeemPeriods_, principals_);
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
        if (origTestParams.length == 0 || splitBefore > origTestParams.length - 1) {
            revert TestParamSet__InvalidSplit(splitBefore, origTestParams.length);
        }

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
