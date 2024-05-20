# Github Actions

## Running ctions Locally

### Pre-requisite
1. Install act https://nektosact.com/installation/index.html
2. Jobs should be run from root folder (.././/)

### List Jobs
List jobs, with optional "--container-architecture" flag for Mac m chips
```bash
act --list --container-architecture linux/amd64
```

### Run jobs
Run all jobs in ci-check-env.yml.  Pass in an .env file as Environment variables and Secrets
```bash
act -W .github/workflows/ci-check-env.yml --var-file packages/contracts/.env --secret-file packages/contracts/.secret --container-architecture linux/amd64
```