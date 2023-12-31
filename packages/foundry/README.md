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
forge test --match-test <testname>
```

## Deploy to Mainnet (or Testnet)
```bash
# Read the environment variables
source .env

# Deploy the contracts (Option 1).  This reads the private key from the environment.
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast

# Deploy the contracts (Option 2).  This will prompt for the sender's key.
forge script script/Deploy.s.sol --rpc-url $RPC_URL --sender $OWNER_ADDRESS --interactives 1 --broadcast
```

## Verify Contract on Mainnet (or Testnet)
```bash
# Read the environment variables
source .env

# Verify the contract source.  
# Replace <OwnerAddress> with the desired contract owner.  Will prompt for the owner's key.
# TODO: separate out Verification step.  This is using `forge create`, should use `forge script`
forge create --rpc-url $RPC_URL \
    --constructor-args "<OwnerAddress>" "1000" \
    --interactive \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --verify \
    contracts/CredbullToken.sol:CredbullToken
```
