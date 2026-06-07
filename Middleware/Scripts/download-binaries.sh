#!/bin/bash
# Downloads the static ffmpeg binary used by convertfile43.
# Copied into the .app bundle at build time by project.yml's preBuildScript.
# Requires: curl, unzip

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARIES_DIR="$SCRIPT_DIR/../binaries"
ARCH=$(uname -m)
mkdir -p "$BINARIES_DIR"

echo "=== ffmpeg (static) ==="
FFMPEG_DEST="$BINARIES_DIR/ffmpeg"
if [ ! -f "$FFMPEG_DEST" ]; then
  if [ "$ARCH" = "arm64" ]; then
    echo "Downloading ffmpeg 8.1 for arm64 (Apple Silicon)..."
    curl -fL "https://www.osxexperts.net/ffmpeg81arm.zip" -o /tmp/ffmpeg81arm.zip
    unzip -o /tmp/ffmpeg81arm.zip ffmpeg -d "$BINARIES_DIR"
    rm -f /tmp/ffmpeg81arm.zip
    # Remove quarantine attributes and ad-hoc sign for Apple Silicon
    xattr -cr "$FFMPEG_DEST" 2>/dev/null || true
    codesign -s - "$FFMPEG_DEST" 2>/dev/null || true
  else
    echo "Downloading ffmpeg 8.0 for x86_64 (Intel)..."
    curl -fL "https://www.osxexperts.net/ffmpeg80intel.zip" -o /tmp/ffmpeg80intel.zip
    unzip -o /tmp/ffmpeg80intel.zip ffmpeg -d "$BINARIES_DIR"
    rm -f /tmp/ffmpeg80intel.zip
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
