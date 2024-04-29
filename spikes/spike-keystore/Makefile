-include .env.local

build:; forge build

anvil: anvil

keystore-add-alice:
	cast wallet import alice --private-key ${LOCAL_PRIVATE_KEY}

keystore-add-bob:
	cast wallet import bob --private-key ${SEPOLIA_PRIVATE_KEY}

deploy-local:
	rm -rf out && forge script script/Counter.s.sol:CounterScript -vvv --rpc-url http://127.0.0.1:8545 --private-key ${LOCAL_PRIVATE_KEY} --broadcast -vvvv

# see https://book.getfoundry.sh/reference/cast/cast-wallet-import
deploy-local-keystore:
	rm -rf out && forge script script/Counter.s.sol:CounterScript -vvv --rpc-url http://127.0.0.1:8545 --account alice  --password "" --broadcast -vvvv

deploy-sepolia:
	 rm -rf out && forge script script/Counter.s.sol:CounterScript -vvv --rpc-url ${RPC_URL} --private-key ${SEPOLIA_PRIVATE_KEY} --broadcast -vvvv

deploy-sepolia-keystore:
	rm -rf out && forge script script/Counter.s.sol:CounterScript -vvv --rpc-url ${RPC_URL} --account bob  --password "" --broadcast -vvvv
