import { loadEnvConfig } from '@next/env';
import { defineConfig } from 'cypress';

const { combinedEnv } = loadEnvConfig(process.cwd());

console.log(combinedEnv);
export default defineConfig({
  env: combinedEnv,
  e2e: {
    setupNodeEvents(_on, _config) {
      // implement node event listeners here
    },
  },
  component: {
    devServer: {
      framework: 'next',
      bundler: 'webpack',
    },
  },
});
