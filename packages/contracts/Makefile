-include .env

build:; forge build

anvil: anvil

define DEPLOY_CMD
	rm -rf out && \
	forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url $(RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) -vvvv && \
	yarn gen-types && yarn db-export
endef


deploy-local:
	$(MAKE) generic-deploy RPC_URL=localhost EXTRA_FLAGS=

# TODO: change this to use the network config from foundry.toml
deploy-sepolia:
	$(MAKE) generic-deploy RPC_URL=$(SEPOLIA_RPC_URL) EXTRA_FLAGS="--verify --slow"

deploy-baseSepolia:
	$(MAKE) generic-deploy RPC_URL=baseSepolia EXTRA_FLAGS="--verify --slow"

generic-deploy:
	@$(DEPLOY_CMD)

verify-sepolia:
	rm -rf out && \
	forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url baseSepolia \
		--private-key $(DEPLOYER_PRIVATE_KEY) --verify --resume -vvvv && \
	yarn gen-types && \
	node script/utils/exporter.js
