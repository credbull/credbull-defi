// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import {ChainUtil} from "../../script/utils/ChainUtil.sol";
import "forge-std/StdChains.sol";

contract ChainUtilTest is Test {
    uint constant private localChainId = 31337;
    uint constant private optimismGoerliChainId = 420;

    function testGetKnownChains() public {
        ChainUtil chainUtil = new ChainUtil();

        Chain memory anvilChain = chainUtil.getAnvilChain();
        assertEq(anvilChain.chainId, localChainId);

        // TODO: fix to remove dependency on environment variable
//        Chain memory optimismGoerli = chainUtil.getOptimismGoerliChain();
//        assertEq(optimismGoerli.chainId, optimismGoerliChainId);
    }

    function testChainsAreEqual() public {
        ChainUtil chainUtil1 = new ChainUtil();
        ChainUtil chainUtil2 = new ChainUtil();

        assert(chainUtil1.chainsAreSame(chainUtil1.getAnvilChain(), chainUtil2.getAnvilChain()));

        // TODO: fix to remove dependency on environment variable
        // assertFalse(chainUtil1.chainsAreSame(chainUtil1.getAnvilChain(), chainUtil2.getOptimismGoerliChain()));
    }

}
