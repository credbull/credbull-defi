# NOTE (JL,2024-05-20): Hierarchical Environment loading does not simply work with `make`. A custom
#	solution may be possible, but given that `forge` auto-loads any `.env` file in the invocation
#	directory and our deployment scripts depend on this, it seems unnecessary to change this now.
-include .env

DEPLOY_SCRIPT ?= script/DeployVaults.s.sol:DeployVaults

deploy-local:
	$(MAKE) deploy RPC_URL=localhost EXTRA_FLAGS=
	$(MAKE) deploy DEPLOY_SCRIPT='script/DeployVaultsSupport.s.sol:DeployVaultsSupport' RPC_URL=localhost EXTRA_FLAGS=

deploy-arbSepolia:
	$(MAKE) deploy RPC_URL=arbitrumSepolia EXTRA_FLAGS="--verify --slow"

resume-arbSepolia:
	$(MAKE) deploy RPC_URL=arbitrumSepolia EXTRA_FLAGS="--verify --slow --resume"

deploy-baseSepolia:
	$(MAKE) deploy RPC_URL=baseSepolia EXTRA_FLAGS="--verify --slow"

deploy:
	@echo "Running deploy script '$(DEPLOY_SCRIPT)' targeting network '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	@yarn clean
	@yarn build
	@yarn run ts-node script/utils/deployedContracts.ts --chain-id $$(cast chain-id --rpc-url $(RPC_URL))
	@forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) --private-key $(DEPLOYER_PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) -vvvv
	@yarn run ts-node script/utils/processDeployment.ts $$(cast chain-id --rpc-url $(RPC_URL))

# TODO: add --verifier flag.  forge isn't happy --etherscan-api-key is empty.
deploy-bitlayerTestnet:
	$(MAKE) deploy RPC_URL="https://testnet-rpc.bitlayer.org" \
	EXTRA_FLAGS='--etherscan-api-key "" --verifier-url "https://testnet-scan.bitlayer.org" --legacy --slow'

verify:
	@echo "Running verify '$(RPC_URL)' for '$(ENVIRONMENT)' environment."
	@yarn clean
	@yarn build
	@forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) --private-key $(DEPLOYER_PRIVATE_KEY) --verify --resume -vvvv
	@yarn run ts-node script/utils/processDeployment.ts $$(cast chain-id --rpc-url $(RPC_URL))
