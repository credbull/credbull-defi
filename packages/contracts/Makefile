-include .env

build:; forge build

anvil: anvil

deploy-local:
	rm -rf out && forge script script/DeployVaultFactory.s.sol:DeployVaultFactory -vvv --rpc-url http://localhost:8545 \
		--private-key ${DEFAULT_ANVIL_KEY} --broadcast -vvvv \
		&& yarn gen-types && node script/utils/exporter.js

deploy-sepolia:
	rm -rf out && forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --slow --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv \
		&& yarn gen-types && node script/utils/exporter.js
