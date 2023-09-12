import {describe, it} from 'mocha';
import {assert} from 'chai';

import {MyNetworkConfig, SAFE_V130, SEPOLIA_CHAINID} from "../src/network-config";
import {SafeVersion} from "@safe-global/safe-core-sdk-types";
import {SingletonDeployment} from "@safe-global/safe-deployments";
import {ContractNetworksConfig} from "@safe-global/protocol-kit";
import {ContractNetworkConfig} from "@safe-global/protocol-kit/dist/src/types";

const chainId: number = SEPOLIA_CHAINID;
const safeVersion: SafeVersion = SAFE_V130; // SAFE contracts 1.4 for Sepolia don't exist in the deployment

const SAFE_ADDRESS_DEFAULT = "0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552";
const SAFE_ADDRESS_SEPOLIA = "0x69f4D1788e39c87893C980c06EdF4b7f686e2938";

// See: https://github.com/safe-global/safe-deployments
describe("Test the Safe Deployments SDK", () => {

    it("Safe Contract addresses should be set correctly for Sepolia ", async () => {
        const myNetworkConfig: MyNetworkConfig = new MyNetworkConfig(chainId, safeVersion);

        const safeSingletonSepolia: SingletonDeployment = myNetworkConfig.getSafeSingletonDeployment();

        assert.isNotNull(safeSingletonSepolia, "Unable to find Sepolia configuration");
        assert.equal(safeSingletonSepolia.version, safeVersion);
        assert.equal(safeSingletonSepolia.defaultAddress, SAFE_ADDRESS_DEFAULT);
        assert.equal(safeSingletonSepolia.networkAddresses[chainId], SAFE_ADDRESS_SEPOLIA);
    });

    it("Contracts Network Configuration should be set correctly for Sepolia", async () => {
        const myNetworkConfig: MyNetworkConfig = new MyNetworkConfig(chainId, safeVersion);

        const contractNetworksConfig: ContractNetworksConfig = myNetworkConfig.createNetworksConfig();
        const contractNetworkConfig: ContractNetworkConfig = contractNetworksConfig[chainId];

        assert.equal(contractNetworkConfig.safeMasterCopyAddress, SAFE_ADDRESS_SEPOLIA);
    });


});

