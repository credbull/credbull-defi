# NOTE (JL,2024-05-20): Hierarchical Environment loading does not simply work with `make`. A custom 
#	solution may be possible, but given that `forge` auto-loads any `.env` file in the invocation 
#	directory and our deployment scripts depend on this, it seems unnecessary to change this now.
-include .env

build:; forge build

anvil: anvil

# NOTE (JL,2024-05-20): `forge` auto-includes any `.env` file in the invocation directory.
define DEPLOY_CMD
	rm -rf out && \
	forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url $(RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) -vvvv && \
	yarn gen-types && \
	yarn db-export
endef

deploy-local:
	@echo "Running 'deploy-local' for '$(ENVIRONMENT)' environment."
	$(MAKE) generic-deploy RPC_URL=localhost EXTRA_FLAGS=

# TODO: change this to use the network config from foundry.toml
deploy-sepolia:
	@echo "Running 'deploy-sepolia' for '$(ENVIRONMENT)' environment."
	$(MAKE) generic-deploy RPC_URL=$(SEPOLIA_RPC_URL) EXTRA_FLAGS="--verify --slow"

deploy-baseSepolia:
	@echo "Running 'deploy-baseSepolia' for '$(ENVIRONMENT)' environment."
	$(MAKE) generic-deploy RPC_URL=baseSepolia EXTRA_FLAGS="--verify --slow"

generic-deploy:
	@$(DEPLOY_CMD)

# TODO (JL,2024-05-20): Should the below command chain use `yarn db-export` instead of directly calling the script?
verify-sepolia:
	rm -rf out && \
	forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url baseSepolia \
		--private-key $(DEPLOYER_PRIVATE_KEY) --verify --resume -vvvv && \
	yarn gen-types && \
	node script/utils/exporter.js
