#!/bin/bash
# Downloads universal (arm64 + x86_64) static binaries for ffmpeg, ImageMagick, Ghostscript
# These are copied into the .app bundle at build time.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARIES_DIR="$SCRIPT_DIR/../binaries"
mkdir -p "$BINARIES_DIR"

echo "=== Downloading ffmpeg (Universal2) ==="
FFMPEG_URL="https://evermeet.cx/ffmpeg/ffmpeg-7.1.7z"
# Alternative: use https://www.osxexperts.net/ for universal builds
# For now, a placeholder is created
echo "Placeholder: download ffmpeg universal binary to $BINARIES_DIR/ffmpeg"

echo "=== Downloading ImageMagick (Universal2) ==="
echo "Placeholder: download magick universal binary to $BINARIES_DIR/magick"

echo "=== Downloading Ghostscript (Universal2) ==="
echo "Placeholder: download gs universal binary to $BINARIES_DIR/gs"

echo "Done. Binaries will be in $BINARIES_DIR"
echo "Update the URLs above with actual download links before building."
