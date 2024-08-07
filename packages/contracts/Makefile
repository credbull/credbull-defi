# NOTE (JL,2024-05-20): Hierarchical Environment loading does not simply work with `make`. A custom
#	solution may be possible, but given that `forge` auto-loads any `.env` file in the invocation
#	directory and our deployment scripts depend on this, it seems unnecessary to change this now.
-include .env

DEPLOY_SCRIPT ?= script/DeployVaultFactory.s.sol:DeployVaultFactory

# How the deployer is authenticated. Can override to use `cast wallet` output or `--account x --password y` etc.
DEPLOYER_AUTHENTICATION ?= --private-key $(DEPLOYER_PRIVATE_KEY)

deploy-local:
	$(MAKE) deploy RPC_URL=localhost EXTRA_FLAGS=

# TODO: change this to use the network config from foundry.toml
deploy-arbitrumSepolia:
	$(MAKE) deploy RPC_URL=arbitrumSepolia EXTRA_FLAGS="--verify --slow"

resume-arbitrumSepolia:
	$(MAKE) deploy RPC_URL=arbitrumSepolia EXTRA_FLAGS="--verify --slow --resume"

deploy-baseSepolia:
	$(MAKE) deploy RPC_URL=baseSepolia EXTRA_FLAGS="--verify --slow"

# TODO: add --verifier flag.  forge isn't happy --etherscan-api-key is empty.
deploy-bitlayerTestnet:
	$(MAKE) deploy RPC_URL="https://testnet-rpc.bitlayer.org" \
		EXTRA_FLAGS='--etherscan-api-key "" --verifier-url "https://testnet-scan.bitlayer.org" --legacy --slow'

# NOTE (JL,2024-05-20): `forge` auto-includes any `.env` file in the invocation directory.
deploy:
	@echo "Running deploy script '$(DEPLOY_SCRIPT)' against '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	@yarn clean
	@yarn build
	forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) --chain-id $$(cast chain-id --rpc-url $(RPC_URL)) \
		$(DEPLOYER_AUTHENTICATION) --broadcast $(EXTRA_FLAGS) -vvvv
	yarn db-export

verify:
	@echo "Running verify of script '$(DEPLOY_SCRIPT)' against '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	@yarn clean
	@yarn build
	forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) $(DEPLOYER_AUTHENTICATION) --verify --resume -vvvv
	yarn db-export
