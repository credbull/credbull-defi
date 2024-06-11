import { Signer, providers } from 'ethers';

export const OWNER_PUBLIC_KEY_LOCAL: string = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

export class TestSigner {
  private _delegate: providers.JsonRpcSigner;

  constructor(index: number, provider: providers.JsonRpcProvider) {
    this._delegate = provider.getSigner(index);
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
  private _alice: TestSigner;
  private _bob: TestSigner;

  constructor(provider: providers.JsonRpcProvider) {
    this._admin = new TestSigner(0, provider);
    this._operator = new TestSigner(1, provider);
    this._custodian = new TestSigner(2, provider);
    this._treasury = new TestSigner(3, provider);
    this._deployer = new TestSigner(4, provider);
    this._rewardVault = new TestSigner(5, provider);
    this._alice = new TestSigner(6, provider);
    this._bob = new TestSigner(7, provider);
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

  get alice(): TestSigner {
    return this._alice;
  }

  get bob(): TestSigner {
    return this._bob;
  }
}
