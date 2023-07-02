# credbull-defi

This guide shows how to build, test, and deploy the Credbull Token smart contract.

## Pre-requisites
Install Foundry: https://book.getfoundry.sh/getting-started/installation

---
## Local Network
### Build and Test Locally
```bash
# Build and compile
forge build

# Run the tests
forge test
```

### Forked Testing
```bash
#Read the environment variables
source .env

# Test against a Forked Network
forge test --mt <TEST_NAME> -vvvv --fork-url $RPC_URL
```

### Code Formatting and Analysis
```bash
# Format the code
forge fmt

# Run the static analyzers, see: https://book.getfoundry.sh/config/static-analyzers
myth analyze src/CredbullToken.sol --solc-json mythril.config.json --execution-timeout 60
```

---
## Deploy to Mainnet (or Testnet)
### Deploy Contract
```bash
#Read the environment variables
source .env

#Deploy the contract
forge script script/DeployCredbullToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Verify Contract
```bash
#Read the environment variables
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
