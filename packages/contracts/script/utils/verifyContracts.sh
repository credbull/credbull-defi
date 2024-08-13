#!/usr/bin/env bash

TX_LOG=$(find broadcast -type f -name "run-latest.json")
CONTRACTS=$(jq -r '.transactions[] | select(.transactionType == "CREATE") | .contractName' ${TX_LOG})
for CONTRACT in ${CONTRACTS} ; do
	ADDRESS=$(jq -r --arg CT ${CONTRACT} '.transactions[] | select(.transactionType == "CREATE" and .contractName == $CT) | .contractAddress' ${TX_LOG})
	SOURCE_FILE=$(find src test script -type f -name "${CONTRACT}*.sol" -not -name "*Test*.sol")
	forge verify-contract ${ADDRESS} ${SOURCE_FILE}:${CONTRACT} --rpc-url ${1:?RPC_URL is required} \
        --skip-is-verified-check --watch
done
