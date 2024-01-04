import { Module } from '@nestjs/common';

import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { AuthenticationController } from './authentication.controller';

@Module({
  imports: [SupabaseModule],
  controllers: [AuthenticationController],
})
export class AuthenticationModule {}
