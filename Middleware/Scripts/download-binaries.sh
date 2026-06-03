#!/bin/bash
# Downloads the static ffmpeg binary used by convertfile43.
# Copied into the .app bundle at build time by project.yml's preBuildScript.
# Requires: curl

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARIES_DIR="$SCRIPT_DIR/../binaries"
ARCH=$(uname -m)
mkdir -p "$BINARIES_DIR"

echo "=== ffmpeg (static) ==="
FFMPEG_DEST="$BINARIES_DIR/ffmpeg"
if [ ! -f "$FFMPEG_DEST" ]; then
  TAG="n8.0.1-1"
  BASE_URL="https://github.com/shaka-project/static-ffmpeg-binaries/releases/download/$TAG"
  if [ "$ARCH" = "arm64" ]; then
    echo "Downloading ffmpeg for arm64..."
    curl -fL "$BASE_URL/ffmpeg-osx-arm64" -o "$FFMPEG_DEST"
  else
    echo "Downloading ffmpeg for x86_64..."
    curl -fL "$BASE_URL/ffmpeg-osx-x64" -o "$FFMPEG_DEST"
  fi
  chmod +x "$FFMPEG_DEST"
  echo "  ffmpeg version: $($FFMPEG_DEST -version 2>&1 | head -1)"
else
  echo "  Already exists, skipping."
fi

echo ""
echo "=== potrace ==="
POTRACE_DEST="$BINARIES_DIR/potrace"
if [ ! -f "$POTRACE_DEST" ]; then
  if which potrace &>/dev/null; then
    cp "$(which potrace)" "$POTRACE_DEST"
    chmod +x "$POTRACE_DEST"
    echo "  Copied from: $(which potrace)"
  else
    echo "  WARNING: potrace not found. Install with: brew install potrace"
  fi
else
  echo "  Already exists, skipping."
fi

echo ""
echo "=== Binaries in $BINARIES_DIR ==="
ls -lh "$BINARIES_DIR"
echo ""
echo "Done. Build the Xcode project with: xcodegen generate && xcodebuild"
