# NOTE (JL,2024-05-20): Hierarchical Environment loading does not simply work with `make`. A custom 
#	solution may be possible, but given that `forge` auto-loads any `.env` file in the invocation 
#	directory and our deployment scripts depend on this, it seems unnecessary to change this now.
-include .env

DEPLOY_SCRIPT ?= script/DeployVaultFactory.s.sol:DeployVaultFactory

build:; forge build

anvil: anvil

deploy-local:
	$(MAKE) deploy RPC_URL=localhost EXTRA_FLAGS=

deploy-arbSepolia:
	$(MAKE) deploy RPC_URL=arbitrumSepolia EXTRA_FLAGS="--verify --slow"

resume-arbSepolia:
	$(MAKE) deploy RPC_URL=arbitrumSepolia EXTRA_FLAGS="--verify --slow --resume"

deploy-baseSepolia:
	$(MAKE) deploy RPC_URL=baseSepolia EXTRA_FLAGS="--verify --slow"

# From https://docs.plumenetwork.xyz/plume/deploying-on-plume/deploy-with-foundry
# Foundry has a bug with gas estimation on L2s (https://github.com/foundry-rs/foundry/issues/6542).  To work-around:
# in foundry.toml set the `evm_version = "cancun"`
# forge script includes `--legacy --skip-simulation`
deploy-plumeTestnet:
	$(MAKE) deploy RPC_URL=plumeTestnet EXTRA_FLAGS="--verify --verifier blockscout --verifier-url https://test-explorer.plumenetwork.xyz/api\? --legacy --skip-simulation --slow"

resume-plumeTestnet:
	$(MAKE) deploy RPC_URL=plumeTestnet EXTRA_FLAGS="--verify --verifier blockscout --verifier-url https://test-explorer.plumenetwork.xyz/api\? --legacy --skip-simulation --slow --resume"

deploy-arbitrum:
	$(MAKE) deploy RPC_URL=arbitrum EXTRA_FLAGS="--verify --slow"

resume-arbitrum:
	$(MAKE) deploy RPC_URL=arbitrum EXTRA_FLAGS="--verify --slow --resume"

# NOTE (JL,2024-05-20): `forge` auto-includes any `.env` file in the invocation directory.
deploy:
	@echo "Running deploy '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	@rm -rf out && \
	forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) --non-interactive -vvv && \
	yarn gen-types && \
	yarn db-export

verify:
	@echo "Running verify '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	rm -rf out && \
	forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) --verify --resume --non-interactive -vvv && \
	yarn gen-types && \
	yarn db-export
