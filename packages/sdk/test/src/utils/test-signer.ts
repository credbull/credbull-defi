import { Signer, Wallet, ethers, providers } from 'ethers';

export const OWNER_PUBLIC_KEY_LOCAL: string = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

export class TestSigner {
  private _delegate: Wallet;

  constructor(index: number, provider: providers.JsonRpcProvider) {
    // TODO: the SDK is expecting a Wallet (that extends Signer).  using mnemonic to set this for now.

    const anvilMnemonic = 'test test test test test test test test test test test junk';
    const path = `m/44'/60'/0'/0/${index}`;
    const hdNode = ethers.utils.HDNode.fromMnemonic(anvilMnemonic);
    this._delegate = new ethers.Wallet(hdNode.derivePath(path), provider);
  }

  getAddress(): Promise<string> {
    const address = this._delegate.getAddress();

    return address;
  }

  getDelegate(): Signer {
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
  private _treasury: TestSigner;
  private _deployer: TestSigner;
  private _rewardVault: TestSigner;
  private _assetManager: TestSigner;
  private _alice: TestSigner;
  private _bob: TestSigner;
  private _charlie: TestSigner;

  constructor(provider: providers.JsonRpcProvider) {
    this._admin = new TestSigner(0, provider);
    this._operator = new TestSigner(1, provider);
    this._custodian = new TestSigner(2, provider);
    this._treasury = new TestSigner(3, provider);
    this._deployer = new TestSigner(4, provider);
    this._rewardVault = new TestSigner(5, provider);
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

  get treasury(): TestSigner {
    return this._treasury;
  }

  get deployer(): TestSigner {
    return this._deployer;
  }

  get rewardVault(): TestSigner {
    return this._rewardVault;
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
