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

* [`spikes/`](./spikes) Any POC or research we do

---

## Setup project locally

- Ìf you only want to work on the contracts, you don't need to setup the whole project. Please go directly to [`contracts/`](./packages/contracts/README.md) and follow the instructions there.
---
- Ensure that you have:
    - NodeJS + Yarn ([install yarn](https://v3.yarnpkg.com/getting-started/install))
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
- NOTE: JL 2024-05-08, `test` for the `sdk` package has been re-named to `int-test` as it was interfering with developer workflow. The Notion [issue](https://www.notion.so/Task-Ensure-sdk-test-does-not-impact-developer-workflow-on-push-etc-b51ce2df722a4b70a74fcaab6134ad66?pvs=4).

---

## Run and Deploy Locally

- Run ``yarn dev``
- Run ```open http://localhost:3000```

## Slack Integration
For subscribing to notifications of interest from the GitHub repository.
This is covered in detail [here](https://github.com/integrations/slack).

### TL;DR
* Install the GitHub app within your Slack Workspace using this [link](https://slack.com/apps/A01BP7R4KNY-github).
* Connect your Slack & GitHub accounts as per instructions (it's time-limited).
* Setup your GitHub subscriptions as desired. For example, to receive notifications for Issue and Pull Request changes, for `credbull-defi`, enter the following in the GitHub app:

  ```/github credbull/credbull-defi unsubscribe commits releases deployments```
* Tune your notifications to taste and enjoy the plethora of information at your fingertips! 
