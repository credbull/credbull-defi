// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";

import { ConfiguredToDeployVaults } from "./Configured.s.sol";

/// @notice The [Script] used to deploy the Credbull Vaults Distribution.
contract DeployVaults is ConfiguredToDeployVaults {
    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Credbull Vaults Distribution.
     * @dev The return values are ignored, but included for test usages.
     *
     * @return fixedYieldVaultFactory The deployed [CredbullFixedYieldVaultFactory].
     * @return upsideVaultFactory The deployed [CredbullUpsideVaultFactory].
     * @return whiteListProvider The deployed [CredbullWhiteListProvider].
     */
    function run()
        external
        returns (
            CredbullFixedYieldVaultFactory fixedYieldVaultFactory,
            CredbullUpsideVaultFactory upsideVaultFactory,
            CredbullWhiteListProvider whiteListProvider
        )
    {
        address owner = owner();
        address operator = operator();
        address[] memory custodians = new address[](1);
        custodians[0] = custodian();

        vm.startBroadcast();
        fixedYieldVaultFactory = new CredbullFixedYieldVaultFactory(owner, operator, custodians);
        upsideVaultFactory = new CredbullUpsideVaultFactory(owner, operator, custodians);
        whiteListProvider = new CredbullWhiteListProvider(operator);
        vm.stopBroadcast();

        return (fixedYieldVaultFactory, upsideVaultFactory, whiteListProvider);
    }
}
