#!/bin/bash
# Build a customized DMG for convertfile43
# Usage: build-dmg.sh <app_path> <version> <output_dmg>

set -euo pipefail

APP_PATH="$1"
VERSION="$2"
DMG_OUTPUT="$3"
STAGING=$(mktemp -d)
DMG_TEMP=$(mktemp).dmg

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -f "$REPO_ROOT/Installer/app-icon.icns" ]; then
  echo "=== Generating app icon (first run) ==="
  bash "$SCRIPT_DIR/generate-app-icon.sh"
fi

echo "=== Setting up staging ==="
cp -R "$APP_PATH" "$STAGING/convertfile43.app"

if [ -f "$REPO_ROOT/Installer/app-icon.icns" ]; then
  mkdir -p "$STAGING/convertfile43.app/Contents/Resources"
  cp "$REPO_ROOT/Installer/app-icon.icns" "$STAGING/convertfile43.app/Contents/Resources/AppIcon.icns"
  # Custom icon flag for Finder (.app in DMG window)
  if command -v fileicon >/dev/null 2>&1; then
    fileicon set "$STAGING/convertfile43.app" "$REPO_ROOT/Installer/app-icon.icns" || true
  fi
fi
ln -s /Applications "$STAGING/Applications"
mkdir "$STAGING/.background"
cp Installer/dmg-bg.png "$STAGING/.background/"
cp Installer/dmg-volume-icon.icns "$STAGING/.VolumeIcon.icns"
cp Installer/dmg.DS_Store "$STAGING/.DS_Store"

echo "=== Creating RW DMG ==="
hdiutil create -volname "convertfile43 $VERSION" \
  -srcfolder "$STAGING" \
  -ov -format UDRW \
  "$DMG_TEMP"
rm -rf "$STAGING"

echo "=== Mounting to set volume icon ==="
MOUNT=$(hdiutil attach "$DMG_TEMP" 2>/dev/null | grep /Volumes | sed 's/.*\/Volumes\//\/Volumes\//')
SetFile -a C "$MOUNT"
hdiutil detach "$MOUNT" -force 2>/dev/null || true

echo "=== Compressing to UDZO ==="
rm -f "$DMG_OUTPUT"
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_OUTPUT"
rm -f "$DMG_TEMP"

echo "=== Done: $DMG_OUTPUT ==="
