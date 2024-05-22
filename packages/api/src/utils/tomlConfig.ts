import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import { load } from 'js-toml';
import * as path from 'path';

class Secret {
  constructor(public value: string) {}

  toString(): string {
    return '***';
  }

  toJSON(): string {
    return this.toString();
  }
}

interface TomlConfig {
  env: {
    ENVIRONMENT: string;
  };
  secret: {
    OPERATOR_PRIVATE_KEY: Secret;
    CUSTODIAN_PRIVATE_KEY: Secret; // TODO - we shouldn't need this in the API
    SUPABASE_SERVICE_ROLE_KEY: Secret;
    SUPABASE_JWT_SECRET: Secret;
    CRON_SECRET: Secret;
    SLACK_TOKEN?: Secret;
  };
  [key: string]: any;
}

@Injectable()
export class TomlConfigService {
  private readonly tomlConfig: TomlConfig;

  constructor(configService: ConfigService) {
    const env = configService.get('ENVIRONMENT', 'local');

    const configFile = path.resolve(__dirname, `../../resource/api-${env}.toml`); // storing here to keep fly.io happy

    console.log(`Loading configuration from: '${configFile}'`);

    const toml = fs.readFileSync(configFile, 'utf8');
    this.tomlConfig = load(toml) as TomlConfig;

    // include Environment into config
    this.tomlConfig.env = this.tomlConfig.env || {}; // ensure config.env exists
    this.tomlConfig.env.ENVIRONMENT = env;

    // add secrets to the Environment
    this.tomlConfig.secret = this.tomlConfig.secret || {}; // ensure config.env exists
    this.tomlConfig.secret.OPERATOR_PRIVATE_KEY = new Secret(configService.getOrThrow('OPERATOR_PRIVATE_KEY'));
    this.tomlConfig.secret.CUSTODIAN_PRIVATE_KEY = new Secret(configService.get('CUSTODIAN_PRIVATE_KEY') || '');
    this.tomlConfig.secret.SUPABASE_SERVICE_ROLE_KEY = new Secret(
      configService.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
    );
    this.tomlConfig.secret.SUPABASE_JWT_SECRET = new Secret(configService.getOrThrow('SUPABASE_JWT_SECRET'));
    this.tomlConfig.secret.CRON_SECRET = new Secret(configService.getOrThrow('CRON_SECRET'));
    this.tomlConfig.secret.SLACK_TOKEN = new Secret(configService.get('SLACK_TOKEN') || '');

    console.log('Successfully loaded configuration:', JSON.stringify(this.tomlConfig, null, 2));
  }

  get config(): TomlConfig {
    return this.tomlConfig;
  }
}
