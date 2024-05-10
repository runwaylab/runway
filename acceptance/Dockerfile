# https://github.com/84codes/crystal-container-images
FROM 84codes/crystal:1.12.1-ubuntu-24.04 AS builder

WORKDIR /app

# install build dependencies
RUN apt-get update && apt-get install libssh2-1-dev -y

# copy vendored dependencies
COPY vendor/linux_x86_64/bin/ vendor/linux_x86_64/bin/

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

WORKDIR /app

######### CUSTOM SECTION PER PROJECT #########

# copy the binary from the builder stage
COPY --from=builder /app/acceptance/ssh_server/keys/ /app/acceptance/ssh_server/keys/
COPY --from=builder /app/bin/runway .

# run the binary
ENTRYPOINT ["./runway"]
