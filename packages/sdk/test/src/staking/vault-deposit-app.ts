import { CredbullFixedYieldVault, CredbullFixedYieldVault__factory } from '@credbull/contracts';

import { Address, DepositStatus } from './deposit';
import { DepositApp } from './deposit-app';
import { VaultDeposit } from './vault-deposit';

export class VaultDepositApp extends DepositApp<VaultDeposit> {
  private _stakingVaultAddress: Address;
  private _stakingVault: CredbullFixedYieldVault;

  constructor() {
    super();
    this._stakingVaultAddress = this._config.evm.address.vault_cbl_staking;

    this._stakingVault = CredbullFixedYieldVault__factory.connect(this._stakingVaultAddress, this._signerWallet);
  }

  protected getDepositType() {
    return VaultDeposit;
  }

  async deposit(deposit: VaultDeposit): Promise<DepositStatus> {
    return await deposit.deposit(this._signerWallet, this._stakingVault);
  }
}
