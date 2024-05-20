import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';

import { ConfigurationModule } from '../../utils/module';

import { SupabaseStrategy } from './auth/supabase.strategy';
import { SupabaseAdminService } from './supabase-admin.service';
import { SupabaseService } from './supabase.service';

@Module({
  imports: [ConfigurationModule, PassportModule],
  providers: [SupabaseService, SupabaseAdminService, SupabaseStrategy],
  exports: [SupabaseService, SupabaseAdminService],
})
export class SupabaseModule {}
