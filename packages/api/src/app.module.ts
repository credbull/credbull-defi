import { ClassSerializerInterceptor, Module, ValidationPipe } from '@nestjs/common';
import { APP_GUARD, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

// import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { SupabaseModule } from './clients/supabase/supabase.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { AuthenticationModule } from './modules/authentication/authentication.module';
import { NotificationsModule } from './modules/notification/notifications.module';
import { VaultsModule } from './modules/vaults/vaults.module';
import * as logger from './utils/logger';
import { ConfigurationModule } from './utils/module';

@Module({
  imports: [
    ConfigurationModule,
    AccountsModule,
    SupabaseModule,
    AuthenticationModule,
    VaultsModule,
    NotificationsModule,
    ScheduleModule.forRoot(),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 10,
      },
    ]),
  ],
  controllers: [AppController],
  providers: [
    { provide: APP_INTERCEPTOR, useValue: logger.interceptor },
    { provide: APP_INTERCEPTOR, useClass: ClassSerializerInterceptor },
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({ whitelist: true, transform: true }),
    },
  ],
})
export class AppModule {}
