# Use the official Rust image.
# https://hub.docker.com/_/rust
FROM rust AS builder

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

WORKDIR /usr/src/rsky
COPY --from=builder /usr/src/rsky/target/release/rsky-relay rsky-relay

# Create a non-root user
RUN groupadd -r rsky && useradd -r -g rsky -u 1001 rsky
RUN chown -R rsky:rsky /usr/src/rsky
USER rsky

LABEL org.opencontainers.image.source=https://github.com/tigwyk/rsky

# Expose the default ports
EXPOSE 9000 9001

# Run the relay service, yep
CMD ["./rsky-relay"]