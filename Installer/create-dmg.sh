#!/bin/bash
# Creates a signed and notarized DMG for convertfile43

set -euo pipefail

APP_NAME="convertfile43"
APP_PATH="./Build/Release/$APP_NAME.app"
DMG_NAME="${APP_NAME}-1.0.0.dmg"
DMG_PATH="./Build/$DMG_NAME"
STAGING_DIR="./Build/dmg-staging"

echo "=== Cleaning ==="
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

echo "=== Copying app ==="
cp -R "$APP_PATH" "$STAGING_DIR/"

echo "=== Creating DMG ==="
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

echo "=== Signing DMG ==="
codesign -s "Developer ID Application" "$DMG_PATH"

echo "=== Notarizing DMG ==="
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait

echo "=== Stapling ==="
xcrun stapler staple "$DMG_PATH"

echo "Done: $DMG_PATH"
