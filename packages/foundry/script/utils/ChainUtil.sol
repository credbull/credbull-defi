// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {StdChains} from "forge-std/StdChains.sol";

/**
 * ChainsUtil exploses chain utility functions from StdChains.sol for scripts/tests.
 * FYI - these methods will not work from within other contracts.
*/
contract ChainUtil is StdChains {
    function getAnvilChain() public returns (Chain memory chain) {
        return getChainByChainId(31337); // anvil / local chain
    }

    function getOptimismGoerliChain() public returns (Chain memory chain) {
        return getChainByChainId(420); // optimism goerli
    }

    function isLocalChain(Chain memory chain) public returns (bool) {
        return chainsAreSame(chain, getAnvilChain());
    }

    function chainsAreSame(Chain memory chain, Chain memory otherChain) public returns (bool) {
        return chain.chainId == otherChain.chainId;
    }

    function getChainByChainId(uint256 chainId) public returns (Chain memory chain) {
        return getChain(chainId);
    }

    function getChainByAlias(string memory chainAlias) public returns (Chain memory chain) {
        return getChain(chainAlias);
    }
}
