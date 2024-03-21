import { CredbullVaultFactory__factory } from '@credbull/contracts';
import { Injectable, OnModuleInit, Scope } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WebClient } from '@slack/web-api';
import { ethers } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';

@Injectable({ scope: Scope.DEFAULT })
export class NotificationsService implements OnModuleInit {
  private operator: string;
  private slack: WebClient;
  constructor(
    private readonly ethers: EthersService,
    private readonly config: ConfigService,
  ) {
    this.operator = this.config.getOrThrow('OPERATOR_ADDRESS');
    this.slack = new WebClient(this.config.getOrThrow('SLACK_TOKEN'));
  }

  onModuleInit() {
    console.log('Notifications has been initialized.');
    //this.startListeningForBlockEvents();
  }

  async startListeningForBlockEvents() {
    console.log('Listening for block events....');
    const provider = await this.ethers.wssProvider();

    const vaultInterface = new ethers.utils.Interface(CredbullVaultFactory__factory.abi);
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
              const parsedLog = vaultInterface.parseLog(log);
              if (parsedLog.name === 'VaultDeployed') {
                msg += `_Vault Deployed_ : ${parsedLog.args.vault} \n_Balance_ : *${balance} ETH* \n\n`;
              }
            });
          } else {
            msg += `_Transfer to_: ${tx.to} \n_Balance_ : *${balance} ETH* \n\n`;
          }

          msg += `<https://polygonscan.com/tx/${tx.transactionHash}|View transaction on explorer> \n\n`;

          await this.slack.chat.postMessage({
            channel: 'C06QJ4G7WPP',
            text: msg,
          });
        }
      }
    });
  }
}
