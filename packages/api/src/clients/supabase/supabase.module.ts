import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';

import { SupabaseStrategy } from './auth/supabase.strategy';
import { SupabaseService } from './supabase.service';

@Module({
  imports: [PassportModule],
  providers: [SupabaseService, SupabaseStrategy],
  exports: [SupabaseService],
})
export class SupabaseModule {}
