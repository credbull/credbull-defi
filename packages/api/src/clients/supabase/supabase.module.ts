import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';

import { SupabaseStrategy } from './auth/supabase.strategy';
import { SupabaseAdminService } from './supabase-admin.service';
import { SupabaseService } from './supabase.service';

@Module({
  imports: [PassportModule],
  providers: [SupabaseService, SupabaseAdminService, SupabaseStrategy],
  exports: [SupabaseService, SupabaseAdminService],
})
export class SupabaseModule {}
