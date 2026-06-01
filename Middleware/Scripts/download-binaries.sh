#!/bin/bash
# Downloads static binaries for ffmpeg, ImageMagick, Ghostscript
# Copied into the .app bundle at build time.
# Requires: curl, lipo (for universal binary), brew (fallback for magick/gs)

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

echo "=== ImageMagick (magick) ==="
MAGICK_DEST="$BINARIES_DIR/magick"
if [ ! -f "$MAGICK_DEST" ]; then
  if command -v magick &>/dev/null; then
    MAGICK_BREW=$(command -v magick)
    echo "Copying from brew: $MAGICK_BREW"
    cp "$MAGICK_BREW" "$MAGICK_DEST"
    echo "  magick version: $($MAGICK_DEST -version 2>&1 | head -1)"
  else
    echo "  NOT FOUND. Install with: brew install imagemagick"
    echo "  Or download a static build from https://imagemagick.org/download/"
  fi
else
  echo "  Already exists, skipping."
fi

echo "=== Ghostscript (gs) ==="
GS_DEST="$BINARIES_DIR/gs"
if [ ! -f "$GS_DEST" ]; then
  if command -v gs &>/dev/null; then
    GS_BREW=$(command -v gs)
    echo "Copying from brew: $GS_BREW"
    # gs is typically a symlink; resolve it and copy the real binary
    cp "$GS_BREW" "$GS_DEST" 2>/dev/null || cp "$(readlink -f "$GS_BREW")" "$GS_DEST" 2>/dev/null || true
    if [ -f "$GS_DEST" ]; then
      chmod +x "$GS_DEST"
      echo "  gs version: $($GS_DEST --version 2>&1)"
    fi
  else
    echo "  NOT FOUND. Install with: brew install ghostscript"
    echo "  Or download from https://ghostscript.com/releases/"
  fi
else
  echo "  Already exists, skipping."
fi

echo ""
echo "=== Binaries in $BINARIES_DIR ==="
ls -lh "$BINARIES_DIR"
echo ""
echo "Done. Build the Xcode project with: xcodegen generate && xcodebuild"
