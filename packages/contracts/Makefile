-include .env

build:; forge build

anvil: anvil

define DEPLOY_CMD
	rm -rf out && forge script script/DeployVaultFactory.s.sol:DeployVaultFactory -vvv --rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) -vvvv \
		&& yarn gen-types && node script/utils/exporter.js
endef

deploy-local:
	$(MAKE) generic-deploy RPC_URL=localhost PRIVATE_KEY=${DEFAULT_ANVIL_KEY} EXTRA_FLAGS=

deploy-sepolia:
	$(MAKE) generic-deploy RPC_URL=baseSepolia PRIVATE_KEY=$(SEPOLIA_PRIVATE_KEY) EXTRA_FLAGS="--verify --slow"

generic-deploy:
	@$(DEPLOY_CMD)

verify-sepolia:
	rm -rf out && forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url baseSepolia \
		--private-key $(SEPOLIA_PRIVATE_KEY) --verify --resume -vvvv \
		&& yarn gen-types && node script/utils/exporter.js


