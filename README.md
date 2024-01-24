<img src="credbull-logo.jpg" alt="Credbull Logo"/>

# credbull-defi

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

- Ensure you have all the environment variables set in `.env`/`.env.local`/etc files in the root of each package. See
  the samples to check which variables are missing (ex: `.env.local.sample`).

- To run locally you first need to install supabsae's
  client, [install the cli](https://github.com/supabase/cli#install-the-cli)
- then run `supabase start` in the root of this repo

## Test Locally

- After the project has been setup locally you can just:

```bash
# Build, compile, run all tests
yarn test
```

---

## Run and Deploy Locally

```bash
# shell #1 - start a local anvil chain
yarn dev
```
