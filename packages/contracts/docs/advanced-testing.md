# credbull-defi

More advanced testing concepts for a Developer audience.

## Pre-requisites
Install Foundry: https://book.getfoundry.sh/getting-started/installation

---
## Static CodeAnalysis
```bash
myth analyze ../src/CredbullToken.sol --solc-json ../mythril.config.json --execution-timeout 60
```

## Estimate Gas Per Test
```bash
forge snapshot
```

## Forked Testing
```bash
#Read the environment variables
source ../.env

# Test against a Forked Network
forge test --mt <TEST_NAME> -vvvv --fork-url $RPC_URL
```



## Code Formatting
```bash
forge fmt --root
```

