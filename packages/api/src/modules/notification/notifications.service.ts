import { CredbullFixedYieldVaultFactory__factory, CredbullUpsideVaultFactory__factory } from '@credbull/contracts';
import { ConsoleLogger, Injectable, OnModuleInit, Scope } from '@nestjs/common';
import { WebClient } from '@slack/web-api';
import { ethers } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { TomlConfigService } from '../../utils/tomlConfig';

@Injectable({ scope: Scope.DEFAULT })
export class NotificationsService implements OnModuleInit {
  private operator: string;

  private slack: WebClient | undefined = undefined;

  constructor(
    private readonly ethers: EthersService,
    private readonly tomlConfigService: TomlConfigService,
    private readonly supabaseAdmin: SupabaseAdminService,
    private readonly logger: ConsoleLogger,
  ) {
    this.logger.setContext(this.constructor.name);
    this.operator = tomlConfigService.config.evm.address.operator;

    const token = tomlConfigService.config.secret.SLACK_TOKEN?.value;
    if (token) {
      this.slack = new WebClient(token);
      this.logger.log('Slack Client created.');
    } else {
      this.logger.log('Console Logging Client created.');
    }
  }

  onModuleInit() {
    this.startListeningForBlockEvents();
  }

  async startListeningForBlockEvents() {
    this.logger.log('Listening for block events....');
    const provider = await this.ethers.wssProvider();

    let vaultInterface = new ethers.utils.Interface(CredbullFixedYieldVaultFactory__factory.abi);
    provider.on('block', async (blockNumber) => {
      const block = await provider.getBlock(blockNumber);
      const transactions = block.transactions;

      let msg = `<!here> \n\n_Operator_ : ${this.operator} \n_Block Number_ : ${blockNumber} \n`;

      for (let i = 0; i < transactions.length; i++) {
        const tx = await provider.getTransactionReceipt(transactions[i]);

        if (tx.from === this.operator) {
          const balance = ethers.utils
            .formatUnits((await provider.getBalance(this.operator)).toString(), 18)
            .toString();
          //Filter create vault event
          if (tx.logs.length > 0) {
            tx.logs.forEach(async (log) => {
              if (await this.isUpsideVault(log)) {
                console.log('true upside vault');
                vaultInterface = new ethers.utils.Interface(CredbullUpsideVaultFactory__factory.abi);
              } else if (await this.isFixedYieldVault(log)) {
                console.log('true fixed yield vault');
                vaultInterface = new ethers.utils.Interface(CredbullFixedYieldVaultFactory__factory.abi);
              } else {
                return;
              }
              const parsedLog = vaultInterface.parseLog(log);
              if (parsedLog.name === 'VaultDeployed') {
                msg += `_Vault Deployed_ : ${parsedLog.args.vault} \n_Balance_ : *${balance} ETH* \n\n`;
              }
            });
          } else {
            msg += `_Transfer to_: ${tx.to} \n_Balance_ : *${balance} ETH* \n\n`;
          }

          msg += `<https://polygonscan.com/tx/${tx.transactionHash}|View transaction on explorer> \n\n`;

          if (this.slack) {
            await this.slack.chat.postMessage({
              channel: 'C06QJ4G7WPP',
              text: msg,
            });
          } else {
            this.logger.log(msg);
          }
        }
      }
    });
  }

  async isUpsideVault(log: ethers.providers.Log) {
    const { data, error } = await this.supabaseAdmin
      .admin()
      .from('contracts_addresses')
      .select()
      .eq('contract_name', 'CredbullUpsideVaultFactory')
      .single();

    if (error) {
      this.logger.error(error);
      return false;
    }

    if (!data) {
      this.logger.error('No factory address');
      return false;
    }

    const addresses = data.address;

    if (addresses.toLocaleLowerCase() === log.address.toLocaleLowerCase()) {
      return true;
    }

    return false;
  }

  async isFixedYieldVault(log: ethers.providers.Log) {
    const { data, error } = await this.supabaseAdmin
      .admin()
      .from('contracts_addresses')
      .select()
      .eq('contract_name', 'CredbullFixedYieldVaultFactory')
      .single();

    if (error) {
      this.logger.error(error);
      return false;
    }

    if (!data) {
      this.logger.error('No factory address');
      return false;
    }

    const addresses = data.address.toLocaleLowerCase();

    if (addresses === log.address.toLocaleLowerCase()) {
      return true;
    }

    return false;
  }
}
