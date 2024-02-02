<img src="credbull-logo.jpg" alt="Credbull Logo"/>

# Credbull DeFI (credbull-defi)

---

## Project Structure

* [`packages/`](./packages) Individual sub-projects
    * [`api/`](./packages/api) Our backend API Server (NestJS)
    * [`app/`](./packages/app) Our frontend app (NextJS)
    * [`contracts/`](./packages/contracts) Smart Contracts and Tests

* [`scripts/`](./scripts) Scripts to automate any manual task we need
    * [`operation/`](./scripts/operation) Scripts for operational tasks

* [`spikes/`](./scripts) Any POC or research we do

---

## Setup project locally

- Ìf you only want to work on the contracts, you don't need to setup the whole project. Please go directly to [`contracts/`](./packages/contracts/README.md) and follow the instructions there.
---
- Ensure that you have:
    - NodeJS + Yarn ([install yarn](https://yarnpkg.com/getting-started/install))
    - Foundry ([install forge](https://book.getfoundry.sh/getting-started/installation))
    - Docker ([install docker](https://docs.docker.com/get-docker/))
    - Supabase CLI ([install the cli](https://github.com/supabase/cli#install-the-cli)) Hint: choose a native client for
      your platform instead of the npm package)

- Run yarn to install dependencies ```yarn install```

- Ensure you have all the environment variables set in `.env`/`.env.local`/etc files in the root of each package. See
  the samples to check which variables are missing (ex: `.env.local.sample`).
  - Most variables should be already configured for local development. Missing variables:
    - /contracts
      - PUBLIC_OWNER_ADDRESS=your-wallet-address
      - PUBLIC_OPERATOR_ADDRESS=your-wallet-address

- Then cd into packages/api and run `supabase start` and follow the instructions from the cli

---

## Test Locally

- After the project has been setup locally you can just ```yarn test```

---

## Run and Deploy Locally

- Run ``yarn dev``
- Run ```open http://localhost:3000```
