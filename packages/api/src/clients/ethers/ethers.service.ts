import { Signer } from '@ethersproject/abstract-signer';
import { Injectable, Scope } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Overrides, Wallet, providers } from 'ethers';

@Injectable({ scope: Scope.DEFAULT })
export class EthersService {
  private readonly deployerKey: string;
  private readonly network: string;
  private readonly network_wss: string;

  constructor(private readonly config: ConfigService) {
    this.deployerKey = config.getOrThrow('ETHERS_DEPLOYER_PRIVATE_KEY');
    this.network = config.getOrThrow('NEXT_PUBLIC_TARGET_NETWORK');
    this.network_wss = config.getOrThrow('NEXT_PUBLIC_TARGET_NETWORK_WSS');
  }

  deployer(): Signer {
    return new Wallet(this.deployerKey, this.provider());
  }

  socketDeployer(): Signer {
    return new Wallet(this.deployerKey, this.socketProvider());
  }

  // TODO: this is only needed while we dont have a real custodian
  custodian(): Signer {
    const custodianKey = this.config.getOrThrow('ETHERS_CUSTODIAN_PRIVATE_KEY');
    return new Wallet(custodianKey, this.provider());
  }

  overrides(): Overrides {
    const env = this.config.getOrThrow('NODE_ENV');
    return env === 'development' ? { gasLimit: 1000000 } : {};
  }

  private provider(): providers.Provider {
    const env = this.config.getOrThrow('NODE_ENV');
    return env === 'development'
      ? new providers.JsonRpcProvider(this.network)
      : new providers.InfuraProvider(this.network, this.config.getOrThrow('ETHERS_INFURA_API_KEY'));
  }

  private socketProvider(): providers.Provider {
    return new providers.WebSocketProvider(this.network_wss);
  }
}
