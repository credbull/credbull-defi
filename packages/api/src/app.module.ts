import { ClassSerializerInterceptor, Module, ValidationPipe } from '@nestjs/common';
import { APP_GUARD, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';

import { AppController } from './app.controller';
import { SupabaseGuard } from './clients/supabase/auth/supabase.guard';
import { AccountsModule } from './modules/accounts/accounts.module';
import { Config } from './utils/module';

@Module({
  imports: [Config.module(), AccountsModule],
  controllers: [AppController],
  providers: [
    { provide: APP_GUARD, useClass: SupabaseGuard },
    { provide: APP_INTERCEPTOR, useClass: ClassSerializerInterceptor },
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({ whitelist: true, transform: true }),
    },
  ],
})
export class AppModule {}
