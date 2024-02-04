import { Signer } from '@ethersproject/abstract-signer';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Overrides, Wallet, providers } from 'ethers';

@Injectable()
export class EthersService {
  private readonly deployerKey: string;
  private isOnRetry: boolean = false; // Prevent running the retry code on every error hanlder call

  constructor(private readonly config: ConfigService) {
    this.deployerKey = config.getOrThrow('ETHERS_DEPLOYER_PRIVATE_KEY');
  }

  async deployer(): Promise<Signer> {
    return new Wallet(this.deployerKey, await this.provider());
  }

  async networkId(): Promise<number> {
    const provider = await this.provider();
    const { chainId } = await provider.getNetwork();
    return chainId;
  }

  // TODO: this is only needed while we dont have a real custodian
  async custodian(): Promise<Signer> {
    const custodianKey = this.config.getOrThrow('ETHERS_CUSTODIAN_PRIVATE_KEY');
    return new Wallet(custodianKey, await this.provider());
  }

  overrides(): Overrides {
    const env = this.config.getOrThrow('NODE_ENV');
    return env === 'development' ? { gasLimit: 1000000 } : {};
  }

  private async provider(): Promise<providers.Provider> {
    const networkProviders = String(this.config.getOrThrow('ETHERS_PROVIDER_URLS')).split(',');
    let provider;

    if (!this.isOnRetry) {
      this.isOnRetry = true;
      let connectionStatus: boolean = false;

      while (!connectionStatus) {
        for (let i = 0; i < networkProviders.length; i++) {
          if (!connectionStatus) {
            provider = await this.retryConnection(networkProviders[i]);

            if (provider !== false) {
              connectionStatus = true;
              break;
            }
          }
        }
      }
    }
    this.isOnRetry = false;
    return provider as providers.Provider;
  }

  private async retryConnection(
    endpoint: string,
    maxRetries = 3,
    interval = 2000,
  ): Promise<providers.Provider | boolean> {
    const env = this.config.getOrThrow('NODE_ENV');
    const provider =
      env === 'development' ? new providers.JsonRpcProvider(endpoint) : new providers.InfuraProvider(endpoint);

    let retries = 0;
    while (retries < maxRetries) {
      try {
        await provider.getNetwork();
        console.log('Connected successfully.');
        return provider;
      } catch (error) {
        console.error(`Connection failed (attempt ${retries + 1}/${maxRetries}):`, error.message);
        retries++;
        await new Promise((resolve) => setTimeout(resolve, interval));
      }
    }
    console.error(`Max retries (${maxRetries}) exceeded. Could not establish connection.`);
    return false;
  }
}
