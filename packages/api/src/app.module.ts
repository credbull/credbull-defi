import { ClassSerializerInterceptor, Module, OnModuleInit, ValidationPipe } from '@nestjs/common';
import { APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';

import { AppController } from './app.controller';
import { SupabaseModule } from './clients/supabase/supabase.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { AuthenticationModule } from './modules/authentication/authentication.module';
import { ErrorsModule } from './modules/errors/errors.module';
import { ListenerModule } from './modules/eventlistener/listener.module';
import { MetaTxModule } from './modules/metatx/metatx.module';
import { VaultsModule } from './modules/vaults/vaults.module';
import { Config } from './utils/module';

@Module({
  imports: [
    Config.module(),
    AccountsModule,
    SupabaseModule,
    AuthenticationModule,
    VaultsModule,
    MetaTxModule,
    ListenerModule,
    ErrorsModule,
    ScheduleModule.forRoot(),
  ],
  controllers: [AppController],
  providers: [
    { provide: APP_INTERCEPTOR, useClass: ClassSerializerInterceptor },
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({ whitelist: true, transform: true }),
    },
  ],
})
export class AppModule implements OnModuleInit {
  onModuleInit() {
    console.log('App module init');
  }
}
