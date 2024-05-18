require('dotenv').config();

const path = require('path');
const fs = require('fs');
const { load } = require('js-toml');

module.exports = {
  loadConfiguration: function () {
    const env = process.env.ENVIRONMENT;
    const configFile = path.resolve(__dirname, `../../resource/${env}.toml`);
    console.log(`Loading configuration from: '${configFile}'`);
    const toml = fs.readFileSync(configFile, 'utf8');
    const config = load(toml);

    console.log('Successfully loaded configuration:', JSON.stringify(config, null, 2));

    // include Environment into config
    // NB - call this after the log statement to avoid logging keys!
    config.env = config.env || {}; // ensure config.env exists
    config.env.ENVIRONMENT = env;
    config.env.SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

    return config;
  },
};
