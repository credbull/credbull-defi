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

```shell
$ forge build
```

### Test

```shell
$ forge test
```
