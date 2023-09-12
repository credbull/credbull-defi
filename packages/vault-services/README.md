# hello-world with Typescript and Yarn
Uses yarn to initialize a basic typscript project.

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

## (Optional) Deploy to custom network
```bash
# set up the custom network Environment variables
cp .env.sample .env
sed -i 's|^NODE_URL=.*|NODE_URL="http://127.0.0.1:8545"|' .env
echo -e '\nPK=<ENTER_KEY>' >> .env

# deploy to the network
npx hardhat deploy-contracts --network custom
```

# Run the app or tests
```bash
# run with typescript
yarn install

# run with typescript
yarn dev

# Run local network in own shell (see One-Time setup above)
yarn hardhat

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

# Safe Contracts v.1.4.1 (not yet supported on Avalanche)
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