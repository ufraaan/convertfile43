#!/bin/bash
# Builds the ffconv Rust binary and copies it to Middleware/binaries/.
# Called from the Xcode build phase and CI.
# Requires: rustc, cargo

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
BINARIES_DIR="$PROJECT_DIR/binaries"
RUST_DIR="$PROJECT_DIR/rust-tool"
mkdir -p "$BINARIES_DIR"

if ! command -v cargo &>/dev/null; then
    echo "warning: cargo not found — skipping ffconv build"
    echo "  install Rust from https://rustup.rs"
    exit 0
fi

echo "Building ffconv (Rust tool)..."
(cd "$RUST_DIR" && cargo build --release --quiet)

# Native arch binary
cp "$RUST_DIR/target/release/ffconv" "$BINARIES_DIR/ffconv"
echo "Copied ffconv to $BINARIES_DIR/ffconv"
ls -lh "$BINARIES_DIR/ffconv"
