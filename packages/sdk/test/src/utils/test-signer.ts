import * as dotenv from 'dotenv';
import { Wallet, ethers, providers } from 'ethers';
import * as path from 'path';

// NOTE (JL,2024-05-20): Hierarchical Environments are loaded from the package's grandparent directory (../..),
//  then the parent (..) and finally the package directory (.) (adjusted for module location).
dotenv.config({
  encoding: 'utf-8',
  path: [
    path.resolve(__dirname, '../../../../../.env'), // credbull-defi (root)
    path.resolve(__dirname, '../../../../.env'), // packages
    path.resolve(__dirname, '../../../.env'), // sdk
  ],
  override: true,
});

export class TestSigner {
  private _delegate: Wallet;

  constructor(index: number, provider: providers.JsonRpcProvider) {
    const path = `m/44'/60'/0'/0/${index}`;
    // const hdNode = ethers.utils.HDNode.fromMnemonic(process.env.TEST_MNEMONIC);
    const hdNode = ethers.utils.HDNode.fromMnemonic('test test test test test test test test test test test junk');
    this._delegate = new ethers.Wallet(hdNode.derivePath(path), provider);
  }

  getAddress(): Promise<string> {
    const address = this._delegate.getAddress();

    return address;
  }

  getDelegate(): Wallet {
    return this._delegate;
  }

  async getBalance(): Promise<bigint> {
    const balance = this._delegate.getBalance();

    return (await balance).toBigInt();
  }
}

export class TestSigners {
  private _admin: TestSigner;
  private _operator: TestSigner;
  private _custodian: TestSigner;
  private _upgrader: TestSigner;
  private _deployer: TestSigner;
  private _treasury: TestSigner;
  private _assetManager: TestSigner;
  private _alice: TestSigner;
  private _bob: TestSigner;
  private _charlie: TestSigner;

  constructor(provider: providers.JsonRpcProvider) {
    this._admin = new TestSigner(0, provider);
    this._operator = new TestSigner(1, provider);
    this._custodian = new TestSigner(2, provider);
    this._upgrader = new TestSigner(3, provider);
    this._deployer = new TestSigner(4, provider);
    this._treasury = new TestSigner(5, provider);
    this._assetManager = new TestSigner(6, provider);
    this._alice = new TestSigner(7, provider);
    this._bob = new TestSigner(8, provider);
    this._charlie = new TestSigner(9, provider);
  }

  get admin(): TestSigner {
    return this._admin;
  }

  get operator(): TestSigner {
    return this._operator;
  }

  get custodian(): TestSigner {
    return this._custodian;
  }

  get upgrader(): TestSigner {
    return this._upgrader;
  }

  get deployer(): TestSigner {
    return this._deployer;
  }

  get treasury(): TestSigner {
    return this._treasury;
  }

  get assetManager(): TestSigner {
    return this._assetManager;
  }

  get alice(): TestSigner {
    return this._alice;
  }

  get bob(): TestSigner {
    return this._bob;
  }

  get charlie(): TestSigner {
    return this._charlie;
  }
}
