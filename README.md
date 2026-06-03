<div align="center">
  <img src="docs/readme-hero.gif" alt="convertfile43" width="480" style="border-radius: 12px;">
  <h1>convertfile43</h1>
  <p>Convert audio, video, images, and documents from your menu bar.</p>
  <p>
    <img src="https://img.shields.io/badge/macOS-14%2B-1d1d1f?logo=apple&style=flat" alt="macOS 14+">
    <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&style=flat" alt="Swift 6.0">
    <img src="https://img.shields.io/badge/Version-0.1.7-1d1d1f?style=flat" alt="Version 0.1.7">
    <img src="https://img.shields.io/badge/License-GPL_v3-1d1d1f?style=flat" alt="GPL v3">
  </p>
</div>

## How it works

1. Copy files in Finder (⌘C).
2. Click the menu bar icon.
3. Pick a format under Audio, Video, Image, or Document.

Converted files appear next to the originals. No windows and no drag-and-drop.

While a job runs:

- The menu bar icon shows live progress.
- FFmpeg jobs can show an **ETA** (for example `42% · 12m left`).
- Image and office jobs show “converting…” instead of a fake 0%.

Open the menu to see the active filename, cancel, or recent results. Settings (presets, parallel jobs, notifications) open from the menu via the standard macOS settings window.

## Features

- Menu bar only - no Dock icon
- Batch conversion - copy many files, convert all at once
- Live progress and FFmpeg-based **ETA** on the status item and in the menu
- “Converting…” state for ImageMagick and LibreOffice (no fake 0%)
- Hardware-accelerated video via VideoToolbox where supported
- Bundled FFmpeg, ffconv (Rust progress wrapper), ImageMagick, Ghostscript, Potrace
- Custom presets in Settings (add, edit, delete)
- Quit warning if a conversion is active; stops ffconv/ffmpeg process trees
- macOS notifications and optional reveal-in-Finder / sound on complete
- Rotating file logs (open from the Logs submenu)

## Requirements

- macOS 14 (Sonoma) or newer

## Installation

1. Download the latest `.dmg` from the [releases page](https://github.com/ufraaan/convertfile43/releases/latest).
2. Open it and drag convertfile43 to Applications.
3. Launch the app and use the menu bar icon.

The app is unsigned. macOS may block the first launch - right-click the app and choose **Open**.

## Supported formats

| Category | Output formats | Engine |
|---|---|---|
| Audio | mp3, aac, flac, ogg, wav | FFmpeg (via ffconv) |
| Video | mp4, mkv, avi, webm, ogv, gif, mov | FFmpeg (VideoToolbox for mp4/mkv/avi where available) |
| Image | jpg, png, webp, avif, ico, pdf, svg | FFmpeg / ImageMagick |
| Office | pdf | LibreOffice |

> [!WARNING]
> Office documents (doc, docx, xls, xlsx, ppt, pptx, odt, odp, ods) convert to PDF only. You must install [LibreOffice](https://www.libreoffice.org) at `/Applications/LibreOffice.app`.

## Usage tips

- **Cancel** - use **Cancel** under the active job in the menu while a conversion runs.
- **Quit** - **Quit convertfile43** warns if a conversion is active, stops ffconv/ffmpeg trees, then quits. If Activity Monitor still shows ffmpeg: search “ffmpeg”, select it, click **Stop** → **Force Quit**. A second alert may remind you after quit.
- **ETA** - based on FFmpeg `speed=` (for example 2.5x). Shown as `12m left` next to percent when available.
- **Large files** - long encodes (for example a 1.5 GB mp4 to mov) can take a long time; progress should update on the icon. Cancel or quit instead of force-quitting from Activity Monitor.
- **Logs** - **Logs** → open log file / folder when a conversion fails.

## Building from source

Needs full **Xcode** (not Command Line Tools only), **XcodeGen**, and **Rust** (for ffconv).

```bash
brew install xcodegen imagemagick   # ImageMagick only needed to generate app icons once
cd /path/to/convertfile43
xcodegen generate
./Middleware/Scripts/download-binaries.sh   # ffmpeg + Homebrew tools → Middleware/binaries/
bash Installer/generate-app-icon.sh       # blue app icon for .app and DMG (optional if pre-generated)
xcodebuild -project convertfile43.xcodeproj -scheme convertfile43 -configuration Release \
  -derivedDataPath ./Build -destination "generic/platform=macOS" build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED=NO
```

ffconv is built automatically by an Xcode pre-build script (`Middleware/Scripts/build-rust-tool.sh`).

### Local DMG

```bash
APP="./Build/Build/Products/Release/convertfile43.app"
bash Installer/build-dmg.sh "$APP" "0.1.7" "convertfile43-0.1.7.dmg"
```

## Tests

```bash
xcodebuild -project convertfile43.xcodeproj -scheme convertfile43 -configuration Debug \
  -derivedDataPath ./Build -destination "platform=macOS" test \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED=NO
```

Integration tests include live FFmpeg progress sampling via `SubprocessRunner`. A long 5-minute encode test uses `Tests/Fixtures/test_5min_input.mp4` (generate with `./Tests/Fixtures/generate.sh`); it skips if the fixture is missing.

## Project layout

| Path | Purpose |
|---|---|
| `FileConverter/App/` | App entry, app delegate |
| `FileConverter/Features/MenuBar/` | Menu UI |
| `FileConverter/Features/Settings/` | Settings tabs |
| `FileConverter/Features/Conversions/` | Orchestrator |
| `FileConverter/Core/` | Models, services, utilities |
| `Middleware/rust-tool/` | ffconv source |
| `Middleware/binaries/` | Bundled CLIs (gitignored) |
| `Installer/` | DMG scripts and assets |

## Acknowledgments

[FFmpeg](https://ffmpeg.org) and [LibreOffice](https://www.libreoffice.org) power the heavy lifting. Thanks to their maintainers.

## License

GPL v3 - see [LICENSE](LICENSE)
