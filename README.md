<img src="credbull-logo.jpg"/>

# credbull-defi

## Package Structure

* [`packages/`](./packages) Individual sub-projects
    * [`api/`](./packages/api) Our backend API Server (NestJS)
    * [`app/`](./packages/api) Our frontend app (NextJS)
    * [`foundry/`](./packages/foundry) Smart Contracts and Tests

---

## Test Locally

- Ensure you have all the environment variables set in `.env`/`.env.local`/etc files in the root of each package. See
  the samples to check which variables are missing (ex: `.env.local.sample`).

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

- If the contract are not deployed, deploy them locally:

```bash
# shell #2 - deploy locally
yarn deploy
```

---

## Deploy & Verify to Mainnet (or Testnet)

**One-time-only**: add the following properties to packages/foundry/.env

```properties
# RPC API Key, e.g. from Alchemy (see https://www.alchemy.com/)
ALCHEMY_API_KEY=<yourAlchemyKey>
# PK of account who will own the deployed contracts 
DEPLOYER_PRIVATE_KEY=<deployerPrivateKey>
# USDC Contract address on the network (see: https://www.circle.com/en/usdc/developers) 
USDC_CONTRACT_ADDRESS=<contractOwnerPK>
```

```bash
# deploy to a named network, e.g. optimismGoerli
yarn deploy --network optimismGoerli
```

```bash
# deploy and verify to a named network, e.g. optimismGoerli
yarn deploy:verify --network optimismGoerli
```

---
