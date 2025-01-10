import { ERC20, ERC20__factory } from '@credbull/contracts';

import { Address } from './deposit';
import { DepositApp } from './deposit-app';
import { Erc20Transfer } from './erc20-transfer';

export class Erc20TransferApp extends DepositApp<Erc20Transfer> {
  private _address: Address;
  private _erc20: ERC20;

  constructor() {
    super();
    this._address = this._config.evm.address.cbl_token;

    this._erc20 = ERC20__factory.connect(this._address, this._signerWallet);
  }

  protected getDepositType() {
    return Erc20Transfer;
  }

  deposit(erc20transfer: Erc20Transfer) {
    return erc20transfer.deposit(this._signerWallet, this._erc20);
  }
}
