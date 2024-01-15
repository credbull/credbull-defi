import { Signer } from '@ethersproject/abstract-signer';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Wallet, providers } from 'ethers';

@Injectable()
export class EthersService {
  private readonly deployerKey: string;
  private readonly network: string;

  constructor(private readonly config: ConfigService) {
    this.deployerKey = config.getOrThrow('ETHERS_DEPLOYER_PRIVATE_KEY');
    this.network = config.getOrThrow('NEXT_PUBLIC_TARGET_NETWORK');
  }

  deployer(): Signer {
    const env = this.config.getOrThrow('NODE_ENV');

    const provider =
      env === 'development'
        ? new providers.JsonRpcProvider(this.network)
        : new providers.InfuraProvider(this.network, this.config.getOrThrow('ETHERS_INFURA_API_KEY'));

    return new Wallet(this.deployerKey, provider);
  }
}
