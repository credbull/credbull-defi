# credbull-defi

This guide shows how to build, test, and deploy the Credbull smart contracts using Foundry.

## Pre-requisites
Install Foundry: https://book.getfoundry.sh/getting-started/installation

---
## Build and Test Locally
```bash
# Build and compile
forge build

# Run the tests
forge test
```

## Deploy to Mainnet (or Testnet)
```bash
# Read the environment variables
source .env

#Deploy the contract
forge script script/DeployCredbullToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Verify Contract on Mainnet (or Testnet)
```bash
# Read the environment variables
source .env

# Verify the contract source
# TODO: separate out Verification step.  This is using `forge create`, should use `forge script`
forge create --rpc-url $RPC_URL \
    --constructor-args 1000 \
    --private-key $PRIVATE_KEY \
    --etherscan-api-key $BLOCKCHAIN_EXPLORER_API_KEY \
    --verify \
    src/CredbullToken.sol:CredbullToken
```
