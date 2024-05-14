import { Signer } from '@ethersproject/abstract-signer';
import { ConsoleLogger, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Overrides, Wallet, providers } from 'ethers';

@Injectable()
export class EthersService {
  private readonly deployerKey: string;

  constructor(
    private readonly config: ConfigService,
    private readonly logger: ConsoleLogger,
  ) {
    this.logger.setContext(this.constructor.name);
    this.deployerKey = config.getOrThrow('ETHERS_DEPLOYER_PRIVATE_KEY'); // woohoo - this is where the private key is coming from
  }

  async operator(): Promise<Signer> {
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

  public async wssProvider(): Promise<providers.WebSocketProvider> {
    console.log(this.config.getOrThrow('WSS_PROVIDER_URLS'));
    const provider = new providers.WebSocketProvider(this.config.getOrThrow('WSS_PROVIDER_URLS'));
    provider._websocket.on('open', () => {
      console.log('WebSocketProvider open');
    });

    provider._websocket.on('close', () => {
      console.log('WebSocketProvider close');
    });

    provider._websocket.on('error', () => {
      console.log('WebSocketProvider error');
    });

    return provider;
  }

  private async provider(): Promise<providers.Provider> {
    const networkProviders = String(this.config.getOrThrow('ETHERS_PROVIDER_URLS')).split(',');

    let provider;
    let connectionStatus: boolean = false;
    for (let i = 0; i < networkProviders.length; i++) {
      if (!connectionStatus) {
        provider = await this.retryConnection(networkProviders[i]);

        if (provider !== false) {
          connectionStatus = true;
          break;
        }
      }
    }

    if (!connectionStatus) {
      this.logger.error(`Could not establish connection.`);
    }

    return provider as providers.Provider;
  }

  private async retryConnection(
    endpoint: string,
    maxRetries = 10,
    interval = 2000,
  ): Promise<providers.Provider | boolean> {
    const provider = new providers.JsonRpcProvider(endpoint);

    let retries = 0;
    while (retries < maxRetries) {
      try {
        await provider.getNetwork();
        this.logger.log(`Connected successfully`);
        return provider;
      } catch (error) {
        this.logger.error(`Connection failed (attempt ${retries + 1}/${maxRetries}):`, error.message);
        retries++;
        await new Promise((resolve) => setTimeout(resolve, interval));
      }
    }

    return false;
  }
}
