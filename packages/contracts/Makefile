# NOTE (JL,2024-05-20): Hierarchical Environment loading does not simply work with `make`. A custom
#	solution may be possible, but given that `forge` auto-loads any `.env` file in the invocation
#	directory and our deployment scripts depend on this, it seems unnecessary to change this now.
-include .env

deploy-local:
	$(MAKE) deploy-alt RPC_URL=localhost EXTRA_FLAGS=

# TODO: change this to use the network config from foundry.toml
deploy-arbSepolia:
	$(MAKE) deploy RPC_URL=arbitrumSepolia EXTRA_FLAGS="--verify --slow"

resume-arbSepolia:
	$(MAKE) deploy RPC_URL=arbitrumSepolia EXTRA_FLAGS="--verify --slow --resume"

deploy-baseSepolia:
	$(MAKE) deploy RPC_URL=baseSepolia EXTRA_FLAGS="--verify --slow"

# NOTE (JL,2024-05-20): `forge` auto-includes any `.env` file in the invocation directory.
deploy:
	@echo "Running deploy '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	@rm -rf out && \
	forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url $(RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) -vvvv && \
	yarn gen-types && \
	yarn db-export $$(cast chain-id --rpc-url $(RPC_URL))

deploy-alt:
	@echo "Running deploy ALT '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	yarn run ts-node script/deployer/canDeploy.ts --chain-id $$(cast chain-id --rpc-url $(RPC_URL)) \
		--deploy-units 'vaults, vaults_support' && \
	forge script script/deployer/DeployVaults.s.sol:DeployVaults --rpc-url $(RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) -vvvv && \
    yarn db-export $$(cast chain-id --rpc-url $(RPC_URL))

# TODO: add --verifier flag.  forge isn't happy --etherscan-api-key is empty.
deploy-bitlayerTestnet:
	$(MAKE) deploy RPC_URL="https://testnet-rpc.bitlayer.org" \
	EXTRA_FLAGS='--etherscan-api-key "" --verifier-url "https://testnet-scan.bitlayer.org" --legacy --slow'

verify:
	@echo "Running verify '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	rm -rf out && \
	forge script script/DeployVaultFactory.s.sol:DeployVaultFactory --rpc-url $(RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) --verify --resume -vvvv && \
	yarn gen-types && \
	yarn db-export
