// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import {ChainsUtil} from "../../script/utils/ChainsUtil.sol";
import "forge-std/StdChains.sol";

contract ChainsUtilTest is Test {
    uint constant private localChainId = 31337;
    uint constant private optimismGoerliChainId = 420;

    function testGetKnownChains() public {
        ChainsUtil chainUtil = new ChainsUtil();

        Chain memory anvilChain = chainUtil.getAnvilChain();
        assertEq(anvilChain.chainId, localChainId);

        Chain memory optimismGoerli = chainUtil.getOptimismGoerliChain();
        assertEq(optimismGoerli.chainId, optimismGoerliChainId);
    }

    function testChainsAreEqual() public {
        ChainsUtil chainUtil1 = new ChainsUtil();
        ChainsUtil chainUtil2 = new ChainsUtil();

        assert(chainUtil1.chainsAreSame(chainUtil1.getAnvilChain(), chainUtil2.getAnvilChain()));
        assert(chainUtil1.chainsAreSame(chainUtil1.getOptimismGoerliChain(), chainUtil2.getOptimismGoerliChain()));

        assertFalse(chainUtil1.chainsAreSame(chainUtil1.getAnvilChain(), chainUtil2.getOptimismGoerliChain()));
    }

    function testIsLocalChain() public {
        Chain memory localChain = Chain ({name: "anotherChain", chainId: localChainId, chainAlias: "", rpcUrl:""});
        ChainsUtil chainUtil = new ChainsUtil();

        assert(chainUtil.isLocalChain(localChain));
    }
}
