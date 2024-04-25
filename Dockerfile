FROM crystallang/crystal:1.12.1 as builder

WORKDIR /app

# copy core scripts
COPY script/preinstall script/preinstall
COPY script/bootstrap script/bootstrap
COPY script/postinstall script/postinstall

# copy all vendored dependencies
COPY lib/ lib/

# copy shard files
COPY shard.lock shard.lock
COPY shard.yml shard.yml

# bootstrap the project
RUN script/bootstrap

# copy all source files (ensure to use a .dockerignore file for efficient copying)
COPY . .

# build the project
RUN script/build

FROM crystallang/crystal:1.12.1

# add curl for healthchecks
RUN apt-get update && apt-get install -y curl

# create a non-root user for security
RUN useradd -m nonroot
USER nonroot

WORKDIR /app

######### CUSTOM SECTION PER PROJECT #########

# copy the binary from the builder stage
COPY --from=builder --chown=nonroot:nonroot /app/bin/crystal-base-template .

# run the binary (adds two numbers together)
CMD ["./crystal-base-template", "234122314", "1234"]
