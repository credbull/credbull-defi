-include .env

build:; forge build

anvil: anvil

define DEPLOY_CMD
	rm -rf out && \
	forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) -vvvv && \
	yarn gen-types && \
	node script/utils/exporter.js
endef

addVault-local:
	node ./script/utils/checkDb.js && \
	forge script script/DeployVaultFactory.s.sol:DeployVault --rpc-url localhost --private-key $(DEFAULT_ANVIL_KEY) --broadcast -vvvv

deploy-local:
	$(MAKE) generic-deploy RPC_URL=localhost PRIVATE_KEY=$(DEFAULT_ANVIL_KEY) EXTRA_FLAGS= ETHERSCAN_API_KEY=

# TODO: change this to use the network config from foundry.toml
deploy-sepolia:
	$(MAKE) generic-deploy RPC_URL=$(SEPOLIA_RPC_URL) PRIVATE_KEY=$(SEPOLIA_PRIVATE_KEY) EXTRA_FLAGS="--verify --slow"

deploy-baseSepolia:
	$(MAKE) generic-deploy RPC_URL=baseSepolia PRIVATE_KEY=$(SEPOLIA_PRIVATE_KEY) EXTRA_FLAGS="--verify --slow"

generic-deploy:
	@$(DEPLOY_CMD)

verify-sepolia:
	rm -rf out && \
	forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url baseSepolia \
		--private-key $(SEPOLIA_PRIVATE_KEY) --verify --resume -vvvv && \
	yarn gen-types && \
	node script/utils/exporter.js
