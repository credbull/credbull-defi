FROM ghcr.io/foundry-rs/foundry:latest

WORKDIR /contracts

# Set production environment
ENV PUBLIC_OWNER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
ENV PUBLIC_OPERATOR_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Copy files
COPY remappings.txt /contracts/remappings.txt
COPY foundry.toml /contracts/foundry.toml
COPY test /contracts/test
COPY src /contracts/src
COPY script /contracts/script
COPY lib /contracts/lib


CMD [ "forge", "test" ]
