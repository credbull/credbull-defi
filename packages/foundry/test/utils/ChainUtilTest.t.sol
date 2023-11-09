// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import {ChainUtil} from "../../script/utils/ChainsUtil.sol";
import "forge-std/StdChains.sol";

contract ChainUtilTest is Test {
    uint constant private localChainId = 31337;
    uint constant private optimismGoerliChainId = 420;

    function testGetKnownChains() public {
        ChainUtil chainUtil = new ChainUtil();

        Chain memory anvilChain = chainUtil.getAnvilChain();
        assertEq(anvilChain.chainId, localChainId);

        Chain memory optimismGoerli = chainUtil.getOptimismGoerliChain();
        assertEq(optimismGoerli.chainId, optimismGoerliChainId);
    }

    function testChainsAreEqual() public {
        ChainUtil chainUtil1 = new ChainUtil();
        ChainUtil chainUtil2 = new ChainUtil();

        assert(chainUtil1.chainsAreSame(chainUtil1.getAnvilChain(), chainUtil2.getAnvilChain()));
        assert(chainUtil1.chainsAreSame(chainUtil1.getOptimismGoerliChain(), chainUtil2.getOptimismGoerliChain()));

        assertFalse(chainUtil1.chainsAreSame(chainUtil1.getAnvilChain(), chainUtil2.getOptimismGoerliChain()));
    }

    function testIsLocalChain() public {
        Chain memory localChain = Chain ({name: "anotherChain", chainId: localChainId, chainAlias: "", rpcUrl:""});
        ChainUtil chainUtil = new ChainUtil();

        assert(chainUtil.isLocalChain(localChain));
    }
}
