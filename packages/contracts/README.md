## Credbull Smart Contracts

All our smart contract reside in this project. 

If you exclusively want to work on the contracts, you don't need to setup the whole project. Follow only the instructions below to setup the contracts locally.

## Setup project locally

- Ensure that you have:
    - Foundry ([install forge](https://book.getfoundry.sh/getting-started/installation))

- Check your foundry installation
```shell
$ forge --help
$ anvil --help
```

## Setup using Docker

- Clone the repository with submodules `git clone --recurse-submodules
- Build the image with `docker build -f Dockerfile -t credbull-contracts .`
- SSH into the container with `docker run --entrypoint "/bin/sh" -it credbull-contracts`
- You can then run `forge` and `anvil` commands as usual

## Foundry Documentation

https://book.getfoundry.sh/

## Usage

### Build

```bash
forge build
```

### Test

```bash
forge test
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