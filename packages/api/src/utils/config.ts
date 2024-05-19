import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import { load } from 'js-toml';
import * as path from 'path';

interface Config {
  env?: {
    ENVIRONMENT?: string;
    SUPABASE_SERVICE_ROLE_KEY?: string;
  };
  [key: string]: any;
}

@Injectable()
export class TomlConfigService {
  private readonly config: Config;

  constructor() {
    const env = process.env.ENVIRONMENT || 'local';
    const configFile = path.resolve(__dirname, `../../resource/${env}.toml`);
    console.log(`Loading configuration from: '${configFile}'`);

    const toml = fs.readFileSync(configFile, 'utf8');
    this.config = load(toml) as Config;

    console.log('Successfully loaded configuration:', JSON.stringify(this.config, null, 2));

    // include Environment into config
    // NB - call this after the log statement to avoid logging keys!
    this.config.env = this.config.env || {}; // ensure config.env exists
    this.config.env.ENVIRONMENT = env;
    this.config.env.SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

    console.log('Successfully loaded configuration:', JSON.stringify(this.config, null, 2));
  }

  get getConfig(): Config {
    return this.config;
  }

  // Add other getter methods for different configuration sections if needed
}
