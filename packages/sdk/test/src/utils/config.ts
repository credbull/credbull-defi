import * as dotenv from 'dotenv';
import * as fs from 'fs';
import { load } from 'js-toml';
import * as path from 'path';

// NOTE (JL,2024-05-20): Hierarchical Environments are loaded from the grandparent directory (../..),
//  then the parent (..) and finally the current directory (.). Override is enabled so that the most
//  specific configuration wins.
dotenv.config({
  path: ['../../.env', '../.env', '.env'],
  override: true,
});

interface Config {
  secret?: {
    SUPABASE_SERVICE_ROLE_KEY?: string;
    SUPABASE_ANONYMOUS_KEY?: string;
    ADMIN_PASSWORD?: string;
    ADMIN_PRIVATE_KEY?: string;
    BOB_PASSWORD?: string;
    BOB_PRIVATE_KEY?: string;
  };
  [key: string]: any;
}

/**
 * Loads the Operations Local Configuration TOML file. Post-processing it to add supported Environment
 * Variables as a 'Secrets' mechanism.
 *
 * @returns A `Config` instance.
 */
export const loadConfiguration = (): Config => {
  const configFile = path.resolve(__dirname, `../../resource/ops-local.toml`);
  console.log(`Loading configuration from: '${configFile}'`);

  const toml = fs.readFileSync(configFile, 'utf8');
  const config: Config = load(toml);

  console.log('Successfully loaded configuration:', JSON.stringify(config, null, 2));

  // include Environment into config
  // NB - call this after the log statement to avoid logging keys!
  config.secret = config.secret || {}; // ensure config.env exists
  config.secret.SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
  config.secret.SUPABASE_ANONYMOUS_KEY = process.env.SUPABASE_ANONYMOUS_KEY;
  config.secret.ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
  config.secret.ADMIN_PRIVATE_KEY = process.env.ADMIN_PRIVATE_KEY;
  config.secret.BOB_PASSWORD = process.env.BOB_PASSWORD;
  config.secret.BOB_PRIVATE_KEY = process.env.BOB_PRIVATE_KEY;

  return config;
};

export default { loadConfiguration };
