require('dotenv').config();

const path = require('path');
const fs = require('fs');
const { load } = require('js-toml');

// Loads the environment-specified TOML configuration file.
export async function loadConfiguration() {
  const env = process.env.ENVIRONMENT;
  const configFile = path.resolve(__dirname, `../../resource/${env}.toml`);
  console.log(`Loading configuration from: '${configFile}'`);
  const toml = fs.readFileSync(configFile, 'utf8');
  const config = load(toml);
  console.log(`Loaded: '${config}'`);
  return config
}
