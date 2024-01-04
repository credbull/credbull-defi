import { ClassSerializerInterceptor, Module, ValidationPipe } from '@nestjs/common';
import { APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';

import { AppController } from './app.controller';
import { SupabaseModule } from './clients/supabase/supabase.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { AuthenticationModule } from './modules/authentication/authentication.module';
import { Config } from './utils/module';

@Module({
  imports: [Config.module(), AccountsModule, SupabaseModule, AuthenticationModule],
  controllers: [AppController],
  providers: [
    { provide: APP_INTERCEPTOR, useClass: ClassSerializerInterceptor },
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({ whitelist: true, transform: true }),
    },
  ],
})
export class AppModule {}
