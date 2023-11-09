// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import {ChainUtil} from "../../script/utils/ChainUtil.sol";
import "forge-std/StdChains.sol";

contract ChainUtilTest is Test {
    uint constant private localChainId = 31337;
    uint constant private optimismGoerliChainId = 420;

    uint private testChainId = 987654;
    string private testChainAlias = "awesomeTestChain";
    Chain private testChain = Chain ({name: testChainAlias, chainId: testChainId, chainAlias: testChainAlias, rpcUrl:"http://localhost:3000"});

    function testSetAndGetChain() public {
        ChainUtil chainUtil = new ChainUtil();

        chainUtil.setChainByAlias(testChainAlias, testChain);

        assertEq(testChainId, chainUtil.getChainByChainId(testChainId).chainId);
        assertEq(testChainAlias, chainUtil.getChainByAlias(testChainAlias).chainAlias);
    }

    function testRevertifChainNotFound() public {
        ChainUtil chainUtil = new ChainUtil();

        // expect revert for a random chain
        vm.expectRevert();
        chainUtil.getChainByChainId(901498);


        // expect revert for a random chain
        vm.expectRevert();
        chainUtil.getChainByAlias("amazing chain that doesn't exist!");
    }

    function testGetLocalChain() public {
        ChainUtil chainUtil = new ChainUtil();

        Chain memory anvilChain = chainUtil.getAnvilChain();
        assertEq(anvilChain.chainId, localChainId);
    }

    function testChainsAreEqual() public {
        ChainUtil chainUtil = new ChainUtil();

        assert(chainUtil.chainsAreSame(testChain, testChain));
        assertFalse(chainUtil.chainsAreSame(testChain, chainUtil.getAnvilChain()));
    }

}
