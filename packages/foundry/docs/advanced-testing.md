# Credbull - Advanced Testing

More advanced testing concepts for a Developer audience.

---
## Static CodeAnalysis
Pre-Req - install Mythril https://mythril-classic.readthedocs.io/en/master/installation.html
```bash
myth analyze ../contracts/CredbullToken.sol --solc-json ../mythril.config.json --execution-timeout 60
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

## Testing on EC2
**PRE-REQ - add custom chain with the public facing IP address**

In first bash shell - Run the forge server.  Set host to accept all inbound requests.
```bash
cd packages/foundry
# set host as 0.0.0.0 to accept all inbound requests
anvil --host 0.0.0.0 --config-out localhost.json
```
In bash shell #2 - Deploy (as usual, nothing special)
```bash
yarn deploy
```
In bash shell #3 - Run the nextjs client, use the public EC2 IP address.
```bash
cd packages/nextjs

# Specify private host in package.json (e.g. "dev-host": "next dev -H 172.31.90.83",)
yarn dev-host
```


## Code Formatting
```bash
forge fmt --root .
```

