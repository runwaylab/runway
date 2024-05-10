# https://github.com/84codes/crystal-container-images
FROM 84codes/crystal:1.12.1-ubuntu-24.04 AS builder

LABEL org.opencontainers.image.title="runway"
LABEL org.opencontainers.image.description="clearing code for take off"
LABEL org.opencontainers.image.source="https://github.com/runwaylab/runway"
LABEL org.opencontainers.image.documentation="https://github.com/runwaylab/runway"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Grant Birkinbine"

WORKDIR /app

# install build dependencies
RUN apt-get update && apt-get install libssh2-1-dev -y

# copy core scripts
COPY script/preinstall script/preinstall
COPY script/update script/update
COPY script/bootstrap script/bootstrap
COPY script/postinstall script/postinstall

# copy all vendored dependencies
COPY lib/ lib/

# copy shard files
COPY shard.lock shard.lock
COPY shard.yml shard.yml

# bootstrap the project
RUN USE_LINUX_VENDOR=true script/bootstrap

# copy all source files (ensure to use a .dockerignore file for efficient copying)
COPY . .

# build the project
RUN script/build

# https://github.com/phusion/baseimage-docker
FROM ghcr.io/phusion/baseimage:noble-1.0.0

# install runtime dependencies
RUN apt-get update && apt-get install libssh2-1-dev libevent-dev -y

# cleanup some non-critical dependencies
RUN apt-get remove -y \
    openssh-server \
    curl && \
    apt-get autoremove -y

WORKDIR /app

######### CUSTOM SECTION PER PROJECT #########

# copy the binary from the builder stage
COPY --from=builder /app/bin/runway .

# run the binary
ENTRYPOINT ["./runway"]
