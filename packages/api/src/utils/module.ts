import { ConfigModule } from '@nestjs/config';

export const Config = {
  module: () =>
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      // NOTE (JL,2024-05-20): nestjs config allows multiple files, with first loaded wins.
      envFilePath: ['.env', '../.env', '../../.env'],
    }),
};
