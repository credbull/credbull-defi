import { CredbullFixedYieldVault, CredbullFixedYieldVault__factory } from '@credbull/contracts';

import { Address, Deposit } from './deposit';
import { DepositApp } from './deposit-app';
import { VaultDeposit } from './vault-deposit';

export class VaultDepositApp extends DepositApp {
  private _stakingVaultAddress: Address;
  private _stakingVault: CredbullFixedYieldVault;

  constructor() {
    super();
    this._stakingVaultAddress = this._config.evm.address.vault_cbl_staking;

    this._stakingVault = CredbullFixedYieldVault__factory.connect(this._stakingVaultAddress, this._tokenOwner);
  }

  deposit(deposit: Deposit) {
    if (!(deposit instanceof VaultDeposit)) {
      throw new Error(`Invalid deposit type: expected VaultDeposit, got ${deposit.constructor.name}`);
    }

    const vaultDeposit: VaultDeposit = deposit;

    return vaultDeposit.deposit(this._tokenOwner, this._stakingVault);
  }
}
