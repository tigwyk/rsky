# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## About rsky

rsky (/ˈrɪski/) is a full implementation of [AT Protocol](https://atproto.com/) in Rust. This is a work-in-progress implementation that includes both reusable crates and specific services for the Blacksky community. The project follows the canonical TypeScript implementation closely but uses Postgres instead of SQLite and S3-compatible storage for better cloud portability.

## Architecture Overview

### Workspace Structure
This is a Cargo workspace with multiple crates organized into two categories:

**Library Crates** (published to crates.io):
- `rsky-common`: shared utilities, time functions, DID resolution helpers  
- `rsky-crypto`: cryptographic signing and key serialization
- `rsky-identity`: DID and handle resolution functionality
- `rsky-lexicon`: AT Protocol schema definition language implementation
- `rsky-syntax`: string parsers for AT Protocol identifiers (handles, DIDs, etc.)
- `rsky-repo`: data storage structures including Merkle Search Trees (MST)

**Service Applications**:
- `rsky-pds`: Personal Data Server using Postgres + S3-compatible storage
- `rsky-relay`: Network crawler and "big-world" data aggregator
- `rsky-feedgen`: Bluesky feed generator for Blacksky community
- `rsky-firehose`: Firehose consumer for AT Protocol events
- `rsky-jetstream-subscriber`: Jetstream firehose consumer
- `rsky-labeler`: Content labeling service
- `rsky-pdsadmin`: Administrative tools for PDS management
- `rsky-satnav`: CAR file and repository explorer

### Key Dependencies
- **Rocket**: Web framework used by services (PDS, feedgen, etc.)
- **Diesel**: ORM with Postgres support, includes migrations
- **Tokio**: Async runtime used throughout
- **Serde**: Serialization with CBOR/JSON support for AT Protocol
- **AT Protocol Libraries**: atrium-api, serde_ipld_dagcbor for protocol compliance

## Development Commands

### Building
```bash
# Build entire workspace
cargo build

# Build specific service 
cargo build -p rsky-pds

# Release build
cargo build --release
```

### Testing
```bash
# Run all tests
cargo test

# Run tests for specific crate
cargo test -p rsky-common

# Run integration tests (some require test databases)
cargo test --test integration_tests
```

### Database Operations
Services that use Postgres (rsky-pds, rsky-feedgen) require database setup:

```bash
# Install diesel CLI if not present
cargo install diesel_cli --no-default-features --features postgres

# Run migrations for PDS
cd rsky-pds && diesel migration run

# Run migrations for feedgen
cd rsky-feedgen && diesel migration run

# Generate schema.rs files
cd rsky-pds && diesel print-schema > src/schema.rs
cd rsky-feedgen && diesel print-schema > src/schema.rs
```

### Running Services
```bash
# Run PDS (requires Postgres + configuration)
cargo run -p rsky-pds

# Run feedgen
cargo run -p rsky-feedgen

# Run firehose consumer
cargo run -p rsky-firehose

# Run relay
cargo run -p rsky-relay

# Run with specific binary (relay has multiple)
cargo run -p rsky-relay --bin rsky-relay-labeler --features labeler
```

### Development Utilities
```bash
# Check dependencies for updates
cargo deps rs/repo/github/blacksky-algorithms/rsky/status.svg

# Format code
cargo fmt

# Lint code
cargo clippy

# Check without building
cargo check
```

## Project-Specific Guidelines

### AT Protocol Compliance
- Implementations should follow the [canonical TypeScript implementation](https://github.com/bluesky-social/atproto) closely
- Use proper AT Protocol data structures and serialization (CBOR for records, JSON for APIs)
- Handle DIDs, handles, and AT URIs according to specifications

### Database Architecture
- PDS and feedgen use separate Postgres schemas ("pds" schema for PDS)
- Diesel migrations are in `migrations/` directories
- Schema files are auto-generated at `src/schema.rs`

### Error Handling
- Use `anyhow::Result` for application errors
- Use `thiserror` for structured error types
- Services use `tracing` for structured logging

### Testing Patterns
- Unit tests use `#[test]` and `#[cfg(test)]`
- Async tests use `#[tokio::test]`
- Integration tests are in `tests/` directories
- Some integration tests use testcontainers for Postgres

### Code Organization
- Common utilities go in `rsky-common`
- Protocol-specific code in appropriate domain crates (identity, lexicon, etc.)
- Service-specific code stays in service crates
- Shared dependencies defined in workspace `Cargo.toml`

### Container Support
Services include Dockerfiles for containerized deployment. The project uses:
- Multi-stage builds for size optimization
- Postgres for persistence
- S3-compatible storage for blobs
- Mailgun for email delivery (PDS)

### Security Considerations
- Cryptographic operations use `secp256k1` for AT Protocol compliance
- URL validation prevents SSRF attacks
- Content validation and sanitization for user inputs
- DID verification for identity operations