# Github Actions

## Running Actions Locally

### Pre-requisite
1. Install act https://nektosact.com/installation/index.html
2. Jobs should be run from root folder (.././/)

### List Jobs
List jobs, with optional "--container-architecture" flag for Mac m chips
```bash
act --list --container-architecture linux/amd64
```

### Run check-env sample jobs
Run all jobs in ci-check-env.yml.  Pass in an .env file as Environment variables and Secrets
```bash
act -W .github/workflows/ci-check-env.yml --var-file packages/contracts/.env --secret-file packages/contracts/.secret --container-architecture linux/amd64
```

### Run Contracts jobs
Runs the contracts job - only the Env should be an .env (configs are in .toml) - local secrets are in .env
```bash
act -W .github/workflows/ci-dev-contracts.yml --var ENVIRONMENT=local --secret-file packages/contracts/.env --container-architecture linux/amd64
```

### Run API jobs
Runs the api job - only the Env should be an .env (configs are in .toml) - local secrets are in .env
```bash
act -W .github/workflows/ci-dev-api.yml --var ENVIRONMENT=local --secret-file packages/api/.env --container-architecture linux/amd64
```

### Run Ops jobs
Runs the ops job - only the Env should be an .env (configs are in .toml) - local secrets are in .env
```bash
act -W .github/workflows/ci-dev-ops.yml --var ENVIRONMENT=ci --secret-file packages/ops/.env --container-architecture linux/amd64
```