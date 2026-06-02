# Test Fixtures

Large media fixtures used by integration tests, generated on demand.

## `test_5min_input.mp4` (~200MB)

Used by `ProcessRunTests.test_progressMonitoring_withLongVideo_reportsMultipleSamples` to verify the live progress monitor in `ConversionOrchestrator`. The test skips if the file is missing, so it doesn't run in normal CI.

Generate with:

```bash
./generate.sh /path/to/ffmpeg
```

The script defaults to the bundled ffmpeg in the Debug build. The file is gitignored because of its size.
