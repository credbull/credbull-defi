import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { TomlConfigService } from './tomlConfig';

// Adjust the path as needed

@Global()
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      // NOTE (JL,2024-05-20): nestjs config allows multiple files, with first loaded wins.
      envFilePath: ['.env', '../.env', '../../.env'],
    }),
  ],
  providers: [TomlConfigService],
  exports: [TomlConfigService],
})
export class ConfigurationModule {}
