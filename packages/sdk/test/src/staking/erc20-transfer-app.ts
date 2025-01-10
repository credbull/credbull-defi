import { OwnableToken, OwnableToken__factory } from '@credbull/contracts';

import { Address } from './deposit';
import { DepositApp } from './deposit-app';
import { Erc20Transfer } from './erc20-transfer';

export class Erc20TransferApp extends DepositApp<Erc20Transfer> {
  private _address: Address;
  private _erc20: OwnableToken;

  constructor() {
    super();
    this._address = this._config.evm.address.vault_cbl_staking;

    this._erc20 = OwnableToken__factory.connect(this._address, this._tokenOwner);
  }

  protected getDepositType() {
    return Erc20Transfer;
  }

  deposit(erc20transfer: Erc20Transfer) {
    return erc20transfer.deposit(this._tokenOwner, this._erc20);
  }
}
