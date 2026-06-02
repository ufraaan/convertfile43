#!/bin/bash
# Run this ONCE locally to generate dmg.DS_Store template
set -euo pipefail

APP_PATH="build/Build/Products/Release/convertfile43.app"
VERSION="0.1.2"
STAGING=$(mktemp -d)
DMG_TEMP=$(mktemp).dmg

echo "=== Setting up staging ==="
cp -R "$APP_PATH" "$STAGING/convertfile43.app"
ln -s /Applications "$STAGING/Applications"
mkdir "$STAGING/.background"
cp Installer/dmg-bg.png "$STAGING/.background/"

echo "=== Creating temp DMG ==="
hdiutil create -volname "convertfile43 $VERSION" \
  -srcfolder "$STAGING" \
  -ov -format UDRW \
  "$DMG_TEMP"
rm -rf "$STAGING"

echo "=== Mounting ==="
MOUNT=$(hdiutil attach "$DMG_TEMP" 2>/dev/null | grep /Volumes | sed 's/.*\/Volumes\//\/Volumes\//')
sleep 2

echo "=== Configuring Finder window ==="
VOLNAME="convertfile43 $VERSION"
open "$MOUNT"
sleep 2

BG_PATH="$MOUNT/.background/dmg-bg.png"

osascript <<EOS
tell application "Finder"
  set theWindow to window "$VOLNAME"
  set current view of theWindow to icon view
  set toolbar visible of theWindow to false
  set statusbar visible of theWindow to false
  set bounds of theWindow to {200, 150, 740, 530}
  tell icon view options of theWindow
    set icon size to 64
    set text size to 11
    set background picture to (POSIX file "$BG_PATH" as alias)
  end tell
  set position of item "convertfile43.app" of theWindow to {130, 180}
  set position of item "Applications" of theWindow to {410, 180}
end tell
EOS

sleep 2

echo "=== Extracting DS_Store ==="
cp "$MOUNT/.DS_Store" Installer/dmg.DS_Store

echo "=== Unmounting ==="
hdiutil detach "$MOUNT" -force 2>/dev/null || true
rm -f "$DMG_TEMP"

echo "=== Done: Installer/dmg.DS_Store generated ==="
