#!/bin/bash
# Generates the 5-minute test video fixture used by test_progressMonitoring_withLongVideo_reportsMultipleSamples.
# The test skips if the file is missing, so this is only needed locally for running the live progress test.
# Resulting file: ~200MB, encodes for ~16 seconds with h264_videotoolbox (produces many progress lines).

set -euo pipefail

FIXTURE_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="$FIXTURE_DIR/test_5min_input.mp4"
FFMPEG="${1:-ffmpeg}"

if [ ! -x "$FFMPEG" ]; then
    echo "ffmpeg not found at: $FFMPEG"
    echo "Usage: $0 /path/to/ffmpeg"
    exit 1
fi

if [ -f "$OUTPUT" ]; then
    echo "Fixture already exists at $OUTPUT"
    ls -lh "$OUTPUT"
    exit 0
fi

mkdir -p "$FIXTURE_DIR"

echo "Generating 5-minute 1280x720 test video..."
"$FFMPEG" -y -hide_banner -loglevel error \
    -f lavfi -i "testsrc2=duration=300:size=1280x720:rate=30" \
    -f lavfi -i "sine=frequency=440:duration=300" \
    -c:v libx264 -preset ultrafast -crf 28 \
    -c:a aac -b:a 64k \
    -shortest \
    "$OUTPUT"

echo "Generated: $OUTPUT"
ls -lh "$OUTPUT"
