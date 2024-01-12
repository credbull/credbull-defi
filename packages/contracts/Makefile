-include .env

build:; forge build

anvil: anvil

deploy-local:
	forge script script/DeployVault.s.sol:DeployVault --rpc-url http://localhost:8545 \
		--private-key ${DEFAULT_ANVIL_KEY} --broadcast -vvvv \
		&& node script/utils/exporter.js

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) \
	--private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv \
	&& node script/utils/exporter.js


