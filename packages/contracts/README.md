# credbull-defi

## Pre-requisites
Install Foundry: https://book.getfoundry.sh/getting-started/installation

## Build
```bash
forge build
```

## Test
```bash
forge test
```

## Deploy
```bash
source .env
```

```bash
forge script script/DeployCredbullToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Deploy and Verify
```bash
source .env
```
_TODO: separate out Verification step_
```bash
forge create --rpc-url $RPC_URL \
    --constructor-args 1000 \
    --private-key $PRIVATE_KEY \
    --etherscan-api-key $BLOCKCHAIN_EXPLORER_API_KEY \
    --verify \
    src/CredbullToken.sol:CredbullToken
```
 

## Formatting and Code analysis
```bash
forge fmt
```
See: https://book.getfoundry.sh/config/static-analyzers
```bash
myth analyze src/CredbullToken.sol --solc-json mythril.config.json --execution-timeout 60
```