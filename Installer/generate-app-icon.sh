#!/bin/bash
# Generates AppIcon PNGs for the asset catalog and Installer/app-icon.icns
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET_ASSETS="$ROOT/FileConverter/Resources/Assets.xcassets/AppIcon.appiconset"
ICONSET_BUILD="$ROOT/Installer/AppIcon.iconset"
MAGICK="$ROOT/Middleware/binaries/magick"
if [ ! -x "$MAGICK" ]; then
  MAGICK="$(command -v magick || command -v convert || true)"
fi
if [ -z "$MAGICK" ]; then
  echo "error: ImageMagick (magick) required. Run Middleware/Scripts/download-binaries.sh or brew install imagemagick." >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
BASE="$WORKDIR/base-1024.png"

# Simple branded tile: blue rounded square + white inner ring (no font dependency)
"$MAGICK" -size 1024x1024 xc:none \
  -fill '#2563EB' -draw "roundrectangle 64,64 960,960 200,200" \
  -fill none -stroke white -strokewidth 56 \
  -draw "roundrectangle 220,220 804,804 140,140" \
  -fill white -draw "circle 512,512 512,700" \
  -fill '#2563EB' -draw "circle 512,512 512,620" \
  "$BASE"

mkdir -p "$ICONSET_ASSETS" "$ICONSET_BUILD"

render() {
  local name="$1"
  local size="$2"
  "$MAGICK" "$BASE" -resize "${size}x${size}" "$ICONSET_ASSETS/$name"
  cp "$ICONSET_ASSETS/$name" "$ICONSET_BUILD/$name"
}

render icon_16x16.png 16
render icon_16x16@2x.png 32
render icon_32x32.png 32
render icon_32x32@2x.png 64
render icon_128x128.png 128
render icon_128x128@2x.png 256
render icon_256x256.png 256
render icon_256x256@2x.png 512
render icon_512x512.png 512
render icon_512x512@2x.png 1024

iconutil -c icns -o "$ROOT/Installer/app-icon.icns" "$ICONSET_BUILD"

cat > "$ICONSET_ASSETS/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

echo "Generated AppIcon PNGs and Installer/app-icon.icns"
