// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";

import { ConfiguredToDeployVaults } from "./Configured.s.sol";

/// @notice The [Script] used to deploy the Credbull Vaults Distribution Unit.
contract DeployVaults is ConfiguredToDeployVaults {
    /// @notice The `forge script` invocation entrypoint. The return values are ignored, but included for test
    ///     extensions.
    /// @return fyvf The deployed [CredbullFixedYieldVaultFactory].
    /// @return uvf The deployed [CredbullUpsideVaultFactory].
    /// @return wlp The deployed [CredbullWhiteListProvider].
    function run()
        external
        returns (CredbullFixedYieldVaultFactory fyvf, CredbullUpsideVaultFactory uvf, CredbullWhiteListProvider wlp)
    {
        address owner = owner();
        address operator = operator();
        address[] memory custodians = new address[](1);
        custodians[0] = custodian();

        vm.startBroadcast();
        fyvf = new CredbullFixedYieldVaultFactory(owner, operator, custodians);
        uvf = new CredbullUpsideVaultFactory(owner, operator, custodians);
        wlp = new CredbullWhiteListProvider(operator);
        vm.stopBroadcast();

        return (fyvf, uvf, wlp);
    }
}
