# Use the official Rust image based on Debian Bullseye for glibc compatibility
# https://hub.docker.com/_/rust
FROM rust:bullseye AS builder

# Copy local code to the container image.
WORKDIR /usr/src/rsky

# Copy the entire workspace to get all dependencies and workspace structure
COPY . .

# Install production dependencies and build a release artifact.
RUN cargo build --release --package rsky-relay

FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# Create a non-root user first
RUN groupadd -r rsky && useradd -r -g rsky -u 1001 rsky

# Set working directory to /data where persistent volume will be mounted
WORKDIR /data

# Copy the binary and make it accessible in PATH
COPY --from=builder /usr/src/rsky/target/release/rsky-relay /usr/local/bin/rsky-relay
RUN chmod +x /usr/local/bin/rsky-relay

# Ensure the data directory is owned by the rsky user
RUN chown -R rsky:rsky /data

USER rsky

LABEL org.opencontainers.image.source=https://github.com/tigwyk/rsky

# Expose the default ports
EXPOSE 9000 9001

# Run the relay service
CMD ["rsky-relay"]
