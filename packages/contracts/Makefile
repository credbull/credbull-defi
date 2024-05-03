-include .env

build:; forge build

anvil: anvil

deploy-local:
	rm -rf out && forge script script/DeployVaultFactory.s.sol:DeployVaultFactory -vvv --rpc-url localhost \
		--private-key ${DEFAULT_ANVIL_KEY} --broadcast -vvvv \
		&& yarn gen-types && node script/utils/exporter.js

deploy-sepolia:
	rm -rf out && forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url baseSepolia \
		--private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --slow -vvvv \
		&& yarn gen-types && node script/utils/exporter.js

verify-sepolia:
	rm -rf out && forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url baseSepolia \
		--private-key $(SEPOLIA_PRIVATE_KEY) --verify --resume -vvvv \
		&& yarn gen-types && node script/utils/exporter.js
