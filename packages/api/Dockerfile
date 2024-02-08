# syntax = docker/dockerfile:1

# Adjust NODE_VERSION as desired
ARG NODE_VERSION=21.5.0
FROM node:${NODE_VERSION}-slim as base

LABEL fly_launch_runtime="NestJS"

# NestJS app lives here
WORKDIR /app

# Set production environment
ENV NODE_ENV="production"

# Copy built application
COPY packages/contracts /app/contracts
COPY packages/api /app/api

# Start the server by default, this can be overwritten at runtime
WORKDIR /app/api
EXPOSE 3000
CMD [ "yarn", "run", "start:prod" ]
