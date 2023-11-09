// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {StdChains} from "forge-std/StdChains.sol";

/**
 * ChainsUtil exploses chain utility functions from StdChains.sol for scripts/tests.
 * FYI - these methods will not work from within other contracts.
*/
contract ChainUtil is StdChains {
    uint256 private localChainId = 31337;

    function getAnvilChain() public returns (Chain memory chain) {
        return getChainByChainId(localChainId); // anvil / local chain
    }

    function setChainByAlias(string memory chainAlias, Chain memory chain) public {
        setChain(chainAlias, chain);
    }

    function getOptimismGoerliChain() public returns (Chain memory chain) {
        return getChainByChainId(420); // optimism goerli
    }

    function isLocalChain() public view returns (bool) {
        return localChainId == block.chainid;
    }

    function chainsAreSame(Chain memory chain, Chain memory otherChain) public pure returns (bool) {
        return chain.chainId == otherChain.chainId;
    }

    function getCurrentChain() public returns (Chain memory chain) {
        return getChain(block.chainid);
    }

    function getChainByChainId(uint256 chainId) public returns (Chain memory chain) {
        return getChain(chainId);
    }

    function getChainByAlias(string memory chainAlias) public returns (Chain memory chain) {
        return getChain(chainAlias);
    }
}
