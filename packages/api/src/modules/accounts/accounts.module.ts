import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { MerkleTreeModule } from '../../clients/merkletree/merkletree.module';
import { MerkleTreeService } from '../../clients/merkletree/merkletree.service';
import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { AccountsController } from './accounts.controller';
import { KycService } from './kyc.service';
import { WalletsService } from './wallets.service';

@Module({
  imports: [SupabaseModule, EthersModule, MerkleTreeModule],
  providers: [KycService, WalletsService, MerkleTreeService],
  controllers: [AccountsController],
  exports: [KycService, WalletsService, MerkleTreeService],
})
export class AccountsModule {}
