import { Signer } from '@ethersproject/abstract-signer';
import { ConsoleLogger, Injectable } from '@nestjs/common';
import { Overrides, Wallet, providers } from 'ethers';

import { TomlConfigService } from '../../utils/tomlConfig';

@Injectable()
export class EthersService {
  private readonly operatorPrivateKey: string;

  constructor(
    private readonly tomlConfigService: TomlConfigService,
    private readonly logger: ConsoleLogger,
  ) {
    this.logger.setContext(this.constructor.name);
    this.operatorPrivateKey = this.tomlConfigService.config.secret.OPERATOR_PRIVATE_KEY.value;
  }

  async operator(): Promise<Signer> {
    return new Wallet(this.operatorPrivateKey, await this.provider());
  }

  async networkId(): Promise<number> {
    const provider = await this.provider();
    const { chainId } = await provider.getNetwork();
    return chainId;
  }

  // TODO: this is only needed while we dont have a real custodian
  async custodian(): Promise<Signer> {
    const custodianKey = this.tomlConfigService.config.secret.CUSTODIAN_PRIVATE_KEY.value;
    return new Wallet(custodianKey, await this.provider());
  }

  overrides(): Overrides {
    const nodeEnv = this.tomlConfigService.config.node_env;
    return nodeEnv === 'development' ? { gasLimit: 1000000 } : {};
  }

  public async wssProvider(): Promise<providers.WebSocketProvider> {
    const wssUrl = this.tomlConfigService.config.services.ethers.wss;
    console.log(wssUrl);
    const provider = new providers.WebSocketProvider(wssUrl);
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
    const ethersUrl = this.tomlConfigService.config.services.ethers.url;

    const networkProviders = String(ethersUrl).split(',');

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

  public async getBlockNumber(): Promise<number> {
    const provider = await this.provider();
    return await provider.getBlockNumber();
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
