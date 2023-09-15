import {ContractNetworksConfig} from "@safe-global/protocol-kit";
import {SafeVersion} from "@safe-global/safe-core-sdk-types";

import {
    DeploymentFilter,
    getCreateCallDeployment,
    getFallbackHandlerDeployment,
    getMultiSendCallOnlyDeployment,
    getMultiSendDeployment,
    getProxyFactoryDeployment,
    getSafeSingletonDeployment,
    getSignMessageLibDeployment,
    getSimulateTxAccessorDeployment,
    SingletonDeployment
} from "@safe-global/safe-deployments";

export const SEPOLIA_CHAINID: number = 11155111;
export const SAFE_V130: SafeVersion = '1.3.0'
export const SAFE_V141: SafeVersion = '1.4.1';

const CHAINID_LOCAL = 31337;

// see: // https://github.com/safe-global/safe-core-sdk/blob/main/guides/integrating-the-safe-core-sdk.md
export function createContractNetworks(chainId: number, safeVersion: SafeVersion) {
    const myNetworkConfig: MyNetworkConfig = new MyNetworkConfig(chainId, safeVersion);

    return myNetworkConfig.createNetworksConfig();
}

export class MyNetworkConfig {
    private chainId: number;
    private safeVersion: SafeVersion;
    private deploymentFilter: DeploymentFilter;

    constructor(chainId: number, safeVersion: SafeVersion) {
        this.chainId = chainId;
        this.safeVersion = safeVersion;
        this.deploymentFilter = this.createDeploymentFilter(chainId, safeVersion);
    }

    private createDeploymentFilter(chainId: number, safeVersion: SafeVersion) {
        // local chains are not configured in the deployment.  we'll use defaults for these.
        if (this.isLocalChain()) return {version: safeVersion};

        return {
            network: String(chainId),
            version: safeVersion
        };
    }

    public isLocalChain() {
        return this.chainId == CHAINID_LOCAL;
    }

    public createNetworksConfig(): ContractNetworksConfig {
        const chainId = this.chainId;

        const contractNetworks: ContractNetworksConfig = {
            [chainId]: {
                safeMasterCopyAddress: this.networkAddressForChain(this.getSafeSingletonDeployment()),
                safeProxyFactoryAddress: this.networkAddressForChain(this.getProxyFactoryDeployment()),

                multiSendAddress: this.networkAddressForChain(this.getMultiSendDeployment()),
                multiSendCallOnlyAddress: this.networkAddressForChain(this.getMultiSendCallOnlyDeployment()),

                // TODO: lucasia do we also need  TokenCallbackHandler?
                fallbackHandlerAddress: this.networkAddressForChain(this.getFallbackHandlerDeployment()),

                signMessageLibAddress: this.networkAddressForChain(this.getSignMessageLibDeployment()),
                createCallAddress: this.networkAddressForChain(this.getCreateCallDeployment()),

                simulateTxAccessorAddress: this.networkAddressForChain(this.getSimulateTxAccessorDeployment()),
            }
        }

        return contractNetworks;
    }

    public getSafeSingletonDeployment(): SingletonDeployment {
        return this.handleUndefined(getSafeSingletonDeployment(this.deploymentFilter));
    }

    getProxyFactoryDeployment(): SingletonDeployment {
        return this.handleUndefined(getProxyFactoryDeployment(this.deploymentFilter));
    }

    getMultiSendDeployment(): SingletonDeployment {
        return this.handleUndefined(getMultiSendDeployment(this.deploymentFilter));
    }

    getMultiSendCallOnlyDeployment(): SingletonDeployment {
        return this.handleUndefined(getMultiSendCallOnlyDeployment(this.deploymentFilter));
    }

    getCreateCallDeployment(): SingletonDeployment {
        return this.handleUndefined(getCreateCallDeployment(this.deploymentFilter));
    }


    getSignMessageLibDeployment(): SingletonDeployment {
        return this.handleUndefined(getSignMessageLibDeployment(this.deploymentFilter));
    }


    getSimulateTxAccessorDeployment(): SingletonDeployment {
        return this.handleUndefined(getSimulateTxAccessorDeployment(this.deploymentFilter));
    }


    getFallbackHandlerDeployment(): SingletonDeployment {
        return this.handleUndefined(getFallbackHandlerDeployment(this.deploymentFilter));
    }

    handleUndefined(singletonDeployment: SingletonDeployment | undefined): SingletonDeployment {
        if (singletonDeployment != undefined) {
            return singletonDeployment;
        } else {
            throw new Error(`Unable to find Singleton for chain=${this.chainId} and version=${this.safeVersion}`);
        }
    }

    networkAddressForChain(singletonDeployment: SingletonDeployment): string {
        if (this.isLocalChain()) {
            let defaultAddress: string = singletonDeployment.defaultAddress;
            //console.debug(`Local chain of id=${this.chainId}, using default address for ${singletonDeployment.contractName} of ${defaultAddress}`)
            return defaultAddress;
        } else {
            return singletonDeployment.networkAddresses[this.chainId];
        }
    }

}