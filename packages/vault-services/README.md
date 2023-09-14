# vault-services
Vault interfaces via the Safe SDK

# One-Time Setup of local safe-contracts 
```bash
# v1.3.0
git submodule add https://github.com/gnosis/safe-contracts/ lib/safe-contracts-1.3.0
cd lib/safe-contracts-1.3.0
git checkout v1.3.0-libs.0

# install dependencies
npm install --save-dev hardhat

# validate by running local network
npx hardhat node
```

## Configure custom network (e.g. for Foundry)
```bash
# set up the custom network Environment variables
cd lib/safe-contracts-1.3.0
cp .env.sample .env
sed -i 's|^NODE_URL=.*|NODE_URL="http://127.0.0.1:8545"|' .env
echo -e '\nPK=<ENTER_KEY>' >> .env
```

# Run the app or tests
```bash
# run with typescript
yarn install

# run with typescript
yarn dev

# Option 1: Start Hardhat in own shell
yarn hardhat

# Option 2: Start Anvil (Foundry) in own shell 
yarn anvil-run-deploy

# run tests
yarn test
```


# VS Code with plug n' play
```bash
# add VS Code SDK (see: https://yarnpkg.com/getting-started/editor-sdks)
yarn dlx @yarnpkg/sdks vscode

# In VS Code install ZipFS: https://marketplace.visualstudio.com/items?itemName=arcanis.vscode-zipfs

yarn install

# if having compiler issues, workaround with pnpify (see: https://yarnpkg.com/advanced/pnpify)
# yarn add @yarnpkg/pnpify --dev
```
---
# Future Features

# One-Time Setup of Safe Allowances Plugin
```bash
# v1.3.0
git submodule add git@github.com:safe-global/safe-modules.git lib/safe-modules-master
cd lib/safe-modules-master/allowances

# install dependencies
yarn

# add missing dependencies 
# TODO: check if we can change these to dev dependencies only (yarn add --dev ...)
yarn add --dev @ethersproject/hash @ethersproject/web eth-gas-reporter @nomicfoundation/ethereumjs-trie @nomicfoundation/ethereumjs-util

#fix typo
sed -i 's/AlowanceModule\.sol/AllowanceModule.sol/' test/test-helpers/artifacts.ts


# run the tests
yarn test
```
# Safe Contracts v.1.4.1
Safe have only deployed their v1.4.1 contracts to a few chains (incl. Ethereum, Gnosis).  The official version remains v.1.3.0.
(see https://github.com/safe-global/safe-deployments/blob/main/src/assets/v1.4.1/safe.json).  The singleton is deployed on Avalanche,
so it is still possible to use Safe v.1.4.1, but requires deploying your own contracts. 
```bash
git submodule add https://github.com/gnosis/safe-contracts/ lib/safe-contracts-1.4.1
cd lib/safe-contracts-1.4.1
git checkout v1.4.1

# install dependencies
yarn
```
## (Optional) Deploy to custom network
```bash
# set up the custom network Environment variables
cp .env.sample .env
sed -i 's|^NODE_URL=.*|NODE_URL="http://127.0.0.1:8545"|' .env
echo -e '\nPK=<ENTER_KEY>' >> .env

# deploy to the network
yarn deploy custom
```

# References:
* SafeSDK: https://github.com/safe-global/safe-core-sdk/tree/main/packages/protocol-kit/src/adapters/ethers
   * Protocol Kit Tutorial: https://docs.safe.global/safe-core-aa-sdk/protocol-kit
* Ethers: https://docs.ethers.org/v5/
* Yarn : https://yarnpkg.com/getting-started/usage
* Testing: https://www.testim.io/blog/mocha-for-typescript-testing/