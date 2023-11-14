<img src="credbull-logo.jpg"/>

# credbull-defi

## Package Structure
* [`packages/`](./packages) Individual sub-projects
   * [`foundry/`](./packages/foundry) Smart Contracts and Tests
   * [`vault-services/`](./packages/vault-services) Vault interfaces via the Safe SDK


---
## Build and Test Locally
```bash
# Build, compile, run all tests
yarn test
```
---
## Run and Deploy Locally
```bash
# shell #1 - start a local anvil chain
yarn chain
```
```bash
# shell #2 - deploy locally
yarn deploy
```
```bash
# shell #3 - start the UI
yarn start
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
## Deploy UI to Vercel.  Connect to a Local Network.
Deploy UI to Vercel.  deployed UI will connect to your local network, e.g. localhost.
```bash
# no flag will deploy to a preview URL.
yarn vercel

# add --prod flag to update the prod URL.  
# yarn vercel --prod
```

## Deploy UI to Vercel.  Connect to a Mainnet (or Testnet).
Deploy UI to Vercel.  deployed UI will connect to the specified network, e.g. optimismGoerli.
```bash
# no flag will deploy to a preview URL.
#yarn vercel

# add --prod flag to update the prod URL.  
yarn vercel --prod
```

### To run the Client, set Enviornment variable. (Nextjs bundles this for the client).
```bash
# specify target network in the Env (e.g. optimismGoerli)
export export NEXT_PUBLIC_TARGET_NETWORK=optimismGoerli
```
