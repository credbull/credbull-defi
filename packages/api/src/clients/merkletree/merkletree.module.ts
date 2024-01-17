import { Module } from '@nestjs/common';

import { SupabaseModule } from '../supabase/supabase.module';
import { SupabaseService } from '../supabase/supabase.service';

import { MerkleTreeService } from './merkletree.service';

@Module({
  imports: [SupabaseModule],
  providers: [MerkleTreeService, SupabaseService],
  exports: [MerkleTreeService],
})
export class MerkleTreeModule {}
