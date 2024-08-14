# Credbull Smart Contracts

All our smart contract reside in this project.

If you exclusively want to work on the contracts, you don't need to setup the whole project. Follow only the instructions below to setup the contracts locally.

## Setup

### Local

- Ensure that you have:

  - Foundry ([install forge](https://book.getfoundry.sh/getting-started/installation))

- Check your foundry installation

```shell
$ forge --help
$ anvil --help
```

### Docker

- Clone the repository with submodules `git clone --recurse-submodules
- Build the image with `docker build -f Dockerfile -t credbull-contracts .`
- SSH into the container with `docker run --entrypoint "/bin/sh" -it credbull-contracts`
- You can then run `forge` and `anvil` commands as usual

## Foundry Documentation

https://book.getfoundry.sh/

## Usage

`yarn` is the Package Manager for this module and all development workflows are encoded as Yarn Scripts. Unfortunately, there is no enforced dependency between Yarn Scripts, so we will document the major steps here and provide an expected/required order.

### Clean

To delete all files and remove all directories that contain build artifacts.

```bash
yarn clean
```

### Build

To compile all Solidity code and generate the `ethers` JavaScript modules.

```bash
yarn build
```

### Test

To run the tests.

```bash
yarn test
```

### Start Anvil

To start the local Anvil instance

```bash
yarn chain
```

### Deploy Contracts

To deploy the contracts to the running local Anvil instance

```bash
yarn deploy
```

## Advanced Testing

1. Code Coverage Summary
   ```bash
   forge test
   ```
1. Code Coverage Report
   1. Install [genhtml](https://manpages.ubuntu.com/manpages/focal/man1/genhtml.1.html)
   2. ```bash
       forge coverage --report lcov
       genhtml lcov.info -o out/coverage
      ```

## Advanced Deployment

Some points of interest:

1. We use `forge script` to deploy.
1. We use `make` to orchestrate the deployments.
1. Post-deployment the created contract details are saved to the specified database.
1. The targeted network is specified via the Forge Alias, configured in `foundry.tomnl`

## Reset Submodules

Update each submodules to latest commit recorded

```bash
# run from project root dir
git submodule update --init --recursive
```

Reset the checked out commit for each submodule

```bash
cd packages/contracts/lib/<SUBMODULE>
git reset --hard HEAD
```
