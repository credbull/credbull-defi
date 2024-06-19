<img src="credbull-logo.jpg" alt="Credbull Logo"/>

# Credbull DeFI (credbull-defi)

---
## Project Structure

* [`packages/`](./packages) Individual sub-projects
    * [`api/`](./packages/api) Our backend API Server (NestJS)
    * [`app/`](./packages/app) Our frontend app (NextJS)
    * [`contracts/`](./packages/contracts) Smart Contracts and Tests
    * [`ops/`](./packages/ops) Scripts for operational tasks

* [`spikes/`](./spikes) Any POC or research we do

---
## Setup project locally

- If you only want to work on the contracts, you don't need to setup the whole project.
Please go directly to [`contracts/`](./packages/contracts/README.md) and follow the instructions there.

## Install Pre-requisite Tools
<<<<<<< HEAD
- NodeJS v21+ ([install node.js](https://nodejs.org/en/learn/getting-started/how-to-install-nodejs))
=======
- NodeJS LTS (v20) ([install node.js](https://nodejs.org/en/learn/getting-started/how-to-install-nodejs))
>>>>>>> 4c8ceee7c87082b354260a8e51d03ed6212c3b40
- Yarn ([install yarn](https://v3.yarnpkg.com/getting-started/install))
- Foundry ([install forge](https://book.getfoundry.sh/getting-started/installation))
- Docker ([install docker](https://docs.docker.com/get-docker/))
- Supabase CLI ([install the cli](https://github.com/supabase/cli#install-the-cli))
  - Hint: choose a native client for your platform instead of the npm package


## Install dependencies
```bash
yarn install
```
## Onetime Setup
1. Setup environment variables in each package
    ```bash
<<<<<<< HEAD
    cp -v .env.sample .env
    cd package/api && cp -v .env.local.sample .env.local && cd -
    cd package/app && cp -v .env.local.sample .env.local && cd -
    cd package/contracts && cp -v .env.sample .env && cd - 
    cd package/sdk && cp -v .env.sample .env && cd - 
=======
    cp -n .env.sample .env
    cd packages/api && cp -n .env.sample .env && cd -
    cd packages/app && cp -n .env.local.sample .env.local && cd -
    cd packages/contracts && cp -n .env.sample .env && cd -
    cd packages/ops && cp -n .env.sample .env && cd -
    cd packages/sdk && cp -n .env.sample .env && cd -
>>>>>>> 4c8ceee7c87082b354260a8e51d03ed6212c3b40
    ```
1. Start the database (Supabase)
    ```bash
    cd packages/api && supabase start && cd -
    ```
1. Setup sdk, see [sdk/README.md](packages/sdk/README.md)
<<<<<<< HEAD
1. Setup op scripts, see [operations/README.md](scripts/operation/README.md). 
=======
1. Setup op scripts, see [operations/README.md](packages/ops/README.md).
>>>>>>> 4c8ceee7c87082b354260a8e51d03ed6212c3b40


## Rum and Test Locally
After completing the above setup, simply run:
```bash
# test all packages
yarn test
```

```bash
<<<<<<< HEAD
# run all pakcages
=======
# run all packages
>>>>>>> 4c8ceee7c87082b354260a8e51d03ed6212c3b40
yarn dev
```

### Open the Application
open http://localhost:3000

---
## Slack Integration
For subscribing to notifications of interest from the GitHub repository.
This is covered in detail [here](https://github.com/integrations/slack).

### TL;DR
* Install the GitHub app within your Slack Workspace using this [link](https://slack.com/apps/A01BP7R4KNY-github).
* Connect your Slack & GitHub accounts as per instructions (it's time-limited).
* Setup your GitHub subscriptions as desired. For example, to receive notifications for Issue and Pull Request changes, for `credbull-defi`, enter the following in the GitHub app:

  ```/github credbull/credbull-defi unsubscribe commits releases deployments```
* Tune your notifications to taste and enjoy the plethora of information at your fingertips!
---
