# https://github.com/84codes/crystal-container-images
FROM 84codes/crystal:1.14.1-ubuntu-24.04 AS builder

LABEL org.opencontainers.image.title="runway"
LABEL org.opencontainers.image.description="clearing code for take off"
LABEL org.opencontainers.image.source="https://github.com/runwaylab/runway"
LABEL org.opencontainers.image.documentation="https://github.com/runwaylab/runway"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Grant Birkinbine"

WORKDIR /app

# install build dependencies
RUN apt-get update && apt-get install libssh2-1-dev unzip wget -y

# install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# copy core scripts
COPY script/ script/

# copy all vendored dependencies
COPY vendor/shards/cache/ vendor/shards/cache/

# copy shard files
COPY shard.lock shard.lock
COPY shard.yml shard.yml
COPY .crystal-version .crystal-version

# bootstrap the project
RUN script/bootstrap --production

# copy all source files (ensure to use a .dockerignore file for efficient copying)
COPY . .

# build the project
RUN script/build --production

# https://github.com/phusion/baseimage-docker
FROM ghcr.io/phusion/baseimage:noble-1.0.0

# install runtime dependencies
RUN apt-get update && apt-get install libssh2-1-dev libevent-dev -y

WORKDIR /app

######### CUSTOM SECTION PER PROJECT #########

# copy the binary from the builder stage
COPY --from=builder /app/bin/runway .

# run the binary
ENTRYPOINT ["./runway"]
