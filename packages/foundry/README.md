# credbull-defi

This guide shows how to build, test, and deploy the Credbull smart contracts using Foundry.

## Pre-requisites
Install Foundry: https://book.getfoundry.sh/getting-started/installation

---
## Build and Test Locally
```bash
# Build and compile
forge build

# Run all tests
forge test

# Run a specific test named <testname>
forge test <testname>
```

## Deploy to Mainnet (or Testnet)
```bash
# Read the environment variables
source .env

# Deploy the contracts (Option 1).  This reads the private key from the environment.
forge script script/DeployCredbullToken.s.sol --sig "deployCredbullToken()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Deploy the contracts (Option 2).  This will prompt for the sender's key.
forge script script/DeployCredbullToken.s.sol --sig "deployCredbullToken()" --rpc-url $RPC_URL --sender $OWNER_ADDRESS --interactives 1 --broadcast
```

## Verify Contract on Mainnet (or Testnet)
```bash
# Read the environment variables
source .env

# Verify the contract source.  This will prompt for the sender's key.
# TODO: separate out Verification step.  This is using `forge create`, should use `forge script`
forge create --rpc-url $RPC_URL \
    --constructor-args 1000 \
    --interactive \
    --etherscan-api-key $BLOCKCHAIN_EXPLORER_API_KEY \
    --verify \
    src/CredbullToken.sol:CredbullToken
```
