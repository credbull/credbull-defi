# syntax = docker/dockerfile:1

# Adjust NODE_VERSION as desired
ARG NODE_VERSION=21.5.0
FROM node:${NODE_VERSION}-slim as base

LABEL fly_launch_runtime="NestJS"

# NestJS app lives here
WORKDIR /app

# Set production environment
ENV NODE_ENV="production"


# Throw-away build stage to reduce size of final image
FROM base as build

SHELL ["/bin/bash", "-c"]

# Install packages needed to build node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential node-gyp pkg-config python-is-python3 curl ca-certificates

RUN curl -L https://foundry.paradigm.xyz | bash
RUN source /root/.bashrc
ENV PATH="~/.foundry/bin:${PATH}"
RUN foundryup

# Install node modules
COPY package.json .
COPY .yarn .yarn
COPY .yarnrc.yml .yarnrc.yml
COPY packages packages
RUN yarn install

# Build application
WORKDIR /app/packages/api
RUN yarn run build


# Final stage for app image
FROM base

# Copy built application
COPY --from=build /app/packages/contracts /app/contracts
COPY --from=build /app/packages/api /app/api

# Start the server by default, this can be overwritten at runtime
WORKDIR /app/api
EXPOSE 3000
CMD [ "yarn", "run", "start:prod" ]
