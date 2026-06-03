#!/usr/bin/env bash
# Mirrors .github/workflows/ci.yml so local runs match GitHub Actions.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Xcode (CI uses 26.5 / 17F42) ==="
xcodebuild -version
if ! xcodebuild -version 2>/dev/null | grep -q "Xcode 26.5"; then
  echo "WARN: switch to Xcode 26.5 to match CI:"
  echo "  sudo xcode-select -s /Applications/Xcode_26.5.app/Contents/Developer"
fi

echo "=== Generate project ==="
command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate

echo "=== Binaries ==="
bash Middleware/Scripts/download-binaries.sh

echo "=== App icon ==="
bash Installer/generate-app-icon.sh

DERIVED=Build
rm -rf "$DERIVED"

echo "=== Build Debug (generic/platform=macOS, same as CI) ==="
xcodebuild -project convertfile43.xcodeproj \
  -scheme convertfile43 \
  -configuration Debug \
  -derivedDataPath "$DERIVED" \
  -destination "generic/platform=macOS" \
  build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  CODE_SIGNING_ALLOWED=NO

echo "=== Test (platform=macOS, same as CI) ==="
xcodebuild -project convertfile43.xcodeproj \
  -scheme convertfile43 \
  -configuration Debug \
  -derivedDataPath "$DERIVED" \
  -destination "platform=macOS" \
  test \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  CODE_SIGNING_ALLOWED=NO

echo "=== CI local mirror: OK ==="
