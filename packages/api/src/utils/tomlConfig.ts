import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import { load } from 'js-toml';
import * as path from 'path';

interface TomlConfig {
  env: {
    ENVIRONMENT: string;
    SUPABASE_JWT_SECRET: string;
    CRON_SECRET: string;
    SLACK_TOKEN?: string;
  };
  [key: string]: any;
}

@Injectable()
export class TomlConfigService {
  private readonly tomlConfig: TomlConfig;

  constructor(configService: ConfigService) {
    //     const env = process.env.ENVIRONMENT || 'local';
    const env = configService.getOrThrow('ENVIRONMENT');

    const configFile = path.resolve(__dirname, `../../resource/${env}.toml`);
    console.log(`Loading configuration from: '${configFile}'`);

    const toml = fs.readFileSync(configFile, 'utf8');
    this.tomlConfig = load(toml) as TomlConfig;

    console.log('Successfully loaded configuration:', JSON.stringify(this.tomlConfig, null, 2));

    // include Environment into config
    // NB - call this after the log statement to avoid logging keys!
    this.tomlConfig.env = this.tomlConfig.env || {}; // ensure config.env exists
    this.tomlConfig.env.ENVIRONMENT = env;
    this.tomlConfig.env.SUPABASE_JWT_SECRET = configService.getOrThrow('SUPABASE_JWT_SECRET');
    this.tomlConfig.env.CRON_SECRET = configService.getOrThrow('CRON_SECRET');
    this.tomlConfig.env.SLACK_TOKEN = configService.get('SLACK_TOKEN');
  }

  get config(): TomlConfig {
    return this.tomlConfig;
  }
}
