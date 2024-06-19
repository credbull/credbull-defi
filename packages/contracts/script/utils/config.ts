import * as dotenv from 'dotenv';
import * as path from 'path';
import * as fs from 'fs';
import { load } from 'js-toml';

// NOTE (JL,2024-05-20): Hierarchical Environments are loaded from the grandparent directory (../..),
//  then the parent (..) and finally the current directory (.). Override is enabled so that the most
//  specific configuration wins.
dotenv.config({
  path: ['../../.env', '../.env', '.env'],
  override: true,
});

interface Config {
  env?: {
    ENVIRONMENT?: string;
    SUPABASE_SERVICE_ROLE_KEY?: string;
  };
  [key: string]: any;
}

export const loadConfiguration = (): Config => {
  const env = process.env.ENVIRONMENT as string;
  const configFile = path.resolve(__dirname, `../../resource/${env}.toml`);
  console.log(`Loading configuration from: '${configFile}'`);

  const toml = fs.readFileSync(configFile, 'utf8');
  const config: Config = load(toml);

  console.log('Successfully loaded configuration:', JSON.stringify(config, null, 2));

  // include Environment into config
  // NB - call this after the log statement to avoid logging keys!
  config.env = config.env || {}; // ensure config.env exists
  config.env.ENVIRONMENT = env;
  config.env.SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

  return config;
};

export default { loadConfiguration };
