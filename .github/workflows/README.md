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

### Run APP jobs

Runs the app job - only the Env should be an .env (configs are in .toml) - local secrets are in .env

```bash
act -W .github/workflows/ci-dev-app.yml  --var-file packages/app/.env.local --secret-file packages/app/.env.local --container-architecture linux/amd64
```

### Run Ops jobs

Runs the ops job - only the Env should be an .env (configs are in .toml) - local secrets are in .env

```bash
act -W .github/workflows/ci-dev-ops.yml --var ENVIRONMENT=ci --secret-file packages/ops/.env --container-architecture linux/amd64
```

### Github Action Limitations

The workflows `ci-dev-sdk.yml` and `ci-dev-ops.yml` are nigh on identical, using a 'local' setup for CI invocation. An attempt to resolve this duplication of content using GitHub's Reusable Workflows was made, but that mechanism has proven unsuitable. As yet, no suitable mechanism is known, so we have duplication.
