<div align="center">
  <img src="docs/readme-hero.gif" alt="convertfile43" width="480" style="border-radius: 12px;">
  <h1>convertfile43</h1>
  <p >Convert audio, video, images, and documents from your menu bar.</p>
  <p>
    <img src="https://img.shields.io/badge/macOS-14%2B-1d1d1f?logo=apple&style=flat" alt="macOS 14+">
    <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&style=flat" alt="Swift 6.0">
    <img src="https://img.shields.io/badge/Version-0.1.7-1d1d1f?style=flat" alt="Version 0.1.7">
    <img src="https://img.shields.io/badge/License-GPL_v3-1d1d1f?style=flat" alt="GPL v3">
  </p>
</div>

## how it works

1. copy files in finder (⌘C)
2. click the menu bar icon
3. pick a format under audio, video, image, or document

converted files show up next to the originals. no windows, no drag-and-drop.

while a job runs:

- menu bar icon shows live progress
- ffmpeg jobs can show an **eta** (e.g. `42% · 12m left`)
- image/office jobs show “converting…” instead of a fake 0%

open the menu to see the active filename, cancel, or recent results. settings (presets, parallel jobs, notifications) live in the standard macos settings window from the menu.

## features

- menu bar only - no dock icon
- batch conversion - copy many files, convert all at once
- live progress and ffmpeg-based **eta** on the status item and in the menu
- “converting…” state for imagemagick and libreoffice (no fake 0%)
- hardware-accelerated video via videotoolbox where supported
- bundled ffmpeg, ffconv (rust progress wrapper), imagemagick, ghostscript, potrace
- custom presets in settings (add / edit / delete)
- quit warning if a conversion is active; stops ffconv/ffmpeg process trees
- macos notifications and optional reveal-in-finder / sound on complete
- rotating file logs (open from the logs submenu)

## requirements

- macos 14 (sonoma) or newer

## installation

1. download the latest `.dmg` from the [releases page](https://github.com/ufraaan/convertfile43/releases/latest)
2. open it and drag convertfile43 to applications
3. launch and use the menu bar icon

the app is unsigned. macos may block the first launch - right-click the app and choose **open**.

## supported formats

| category | output formats | engine |
|---|---|---|
| audio | mp3, aac, flac, ogg, wav | ffmpeg (via ffconv) |
| video | mp4, mkv, avi, webm, ogv, gif, mov | ffmpeg (videotoolbox for mp4/mkv/avi where available) |
| image | jpg, png, webp, avif, ico, pdf, svg | ffmpeg / imagemagick |
| office | pdf | libreoffice |

> [!WARNING]
> office documents (doc, docx, xls, xlsx, ppt, pptx, odt, odp, ods) convert to pdf only. you must install [libreoffice](https://www.libreoffice.org) at `/Applications/LibreOffice.app`.

## usage tips

- **cancel** - use **cancel** under the active job in the menu while a conversion runs
- **quit** - **quit convertfile43** warns if a conversion is active, stops ffconv/ffmpeg trees, then quits. if activity monitor still shows ffmpeg: search “ffmpeg”, select it, click **stop** → **force quit**. a second alert may remind you after quit
- **eta** - based on ffmpeg `speed=` (e.g. 2.5x). shown as `12m left` next to percent when available
- **large files** - long encodes (e.g. 1.5 gb mp4 → mov) can take a long time; progress should update on the icon. cancel or quit instead of force-quitting from activity monitor
- **logs** - `logs` → open log file / folder when a conversion fails

## building from source

needs full **xcode** (not command-line tools only), **xcodegen**, and **rust** (for ffconv).

```bash
brew install xcodegen imagemagick   # imagemagick only needed to generate app icons once
cd /path/to/convertfile43
xcodegen generate
./Middleware/Scripts/download-binaries.sh   # ffmpeg + homebrew tools → Middleware/binaries/
bash Installer/generate-app-icon.sh           # blue app icon for .app and dmg (optional if pre-generated)
xcodebuild -project convertfile43.xcodeproj -scheme convertfile43 -configuration Release \
  -derivedDataPath ./Build -destination "generic/platform=macOS" build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED=NO
```

ffconv is built automatically by an xcode pre-build script (`Middleware/Scripts/build-rust-tool.sh`).

### local dmg

```bash
APP="./Build/Build/Products/Release/convertfile43.app"
bash Installer/build-dmg.sh "$APP" "0.1.7" "convertfile43-0.1.7.dmg"
```

## tests

```bash
xcodebuild -project convertfile43.xcodeproj -scheme convertfile43 -configuration Debug \
  -derivedDataPath ./Build -destination "platform=macOS" test \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED=NO
```

integration tests include live ffmpeg progress sampling via `SubprocessRunner`. a long 5-minute encode test uses `Tests/Fixtures/test_5min_input.mp4` (generate with `./Tests/Fixtures/generate.sh`); it skips if the fixture is missing.

## project layout

| path | purpose |
|---|---|
| `FileConverter/App/` | app entry, app delegate |
| `FileConverter/Features/MenuBar/` | menu ui |
| `FileConverter/Features/Settings/` | settings tabs |
| `FileConverter/Features/Conversions/` | orchestrator |
| `FileConverter/Core/` | models, services, utilities |
| `Middleware/rust-tool/` | ffconv source |
| `Middleware/binaries/` | bundled clis (gitignored) |
| `Installer/` | dmg scripts and assets |

## acknowledgments

[ffmpeg](https://ffmpeg.org) and [libreoffice](https://www.libreoffice.org) power the heavy lifting. thanks to their maintainers.

## license

gpl v3 - see [license](LICENSE)
