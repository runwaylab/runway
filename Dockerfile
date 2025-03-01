# https://github.com/84codes/crystal-container-images
# FROM 84codes/crystal:1.14.1-ubuntu-24.04 AS builder
FROM 84codes/crystal@sha256:9f84ce6b226a1814c33250eed86e7ca073dbbd7130d41fc6a1a8c56dfd0c6111 AS builder


LABEL org.opencontainers.image.title="runway"
LABEL org.opencontainers.image.description="clearing code for take off"
LABEL org.opencontainers.image.source="https://github.com/runwaylab/runway"
LABEL org.opencontainers.image.documentation="https://github.com/runwaylab/runway"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Grant Birkinbine"

WORKDIR /app

# update packages
RUN apt-get update && apt-get upgrade -y

# install build dependencies
RUN apt-get install libssh2-1-dev unzip wget -y

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
FROM phusion/baseimage@sha256:b05855f2aa91a1d887d26039d203b65f6d1c7f64191cff786c6deff439af17f3

# install runtime dependencies
RUN apt-get update && apt-get install libssh2-1-dev libevent-dev -y

WORKDIR /app

######### CUSTOM SECTION PER PROJECT #########

# copy the binary from the builder stage
COPY --from=builder /app/bin/runway .

# run the binary
ENTRYPOINT ["./runway"]
