<div align="center">
  <img src="docs/left.jpg" alt="convertfile43" width="200" style="border-radius: 16px;">
  <br><br>
  <h1>convertfile43</h1>
  <p>Convert audio, video, images, and documents from your menu bar.</p>
  <br>
  <p>
    <img src="https://img.shields.io/badge/macOS-14%2B-1d1d1f?logo=apple&style=flat" alt="macOS 14+">
    <img src="https://img.shields.io/github/v/release/ufraaan/FileConverter?label=version&style=flat" alt="Version">
    <img src="https://img.shields.io/github/license/ufraaan/FileConverter?style=flat" alt="License">
  </p>
</div>

<br>

## How it works

1. **Copy** files in Finder (Cmd+C)
2. **Click** the menu bar icon
3. **Pick** a format under Audio, Video, Image, or Document
4. **Done** -- converted files appear next to the originals

No windows, no drag-and-drop, no settings to configure. Just the menu bar.

## Features

- **Menu bar only** -- no Dock icon, stays out of your way
- **Batch conversion** -- copy dozens of files, convert all at once
- **Bundled tools** -- ffmpeg, ImageMagick, and Ghostscript included
- **LibreOffice support** -- convert Word, Excel, and PowerPoint to PDF (requires LibreOffice)
- **Notifications** -- macOS notification on completion

## Requirements

- macOS 14 (Sonoma) or later

## Installation

1. Download the latest `.dmg` from the [releases page](https://github.com/ufraaan/FileConverter/releases/latest)
2. Open the DMG and drag **convertfile43** to your Applications folder
3. Launch the app -- look for the icon in your menu bar

> **Note:** The app is unsigned. On first launch, macOS may show a warning. Right-click the app and select **Open** to bypass it.

## Supported formats

| Category | Output formats | Engine |
|---|---|---|
| Audio | MP3, AAC, FLAC, OGG, WAV | ffmpeg |
| Video | MP4, MKV, AVI, WebM, OGV, GIF | ffmpeg |
| Image | JPG, PNG, WebP, AVIF, ICO | ImageMagick |
| Document | PDF | ImageMagick, Ghostscript, LibreOffice |
| Office* | PDF | LibreOffice |

\* Office documents (doc, docx, xls, xlsx, ppt, pptx, odt, odp, ods) require [LibreOffice](https://www.libreoffice.org) installed.

## Building from source

```bash
brew install xcodegen
xcodegen generate
./Middleware/Scripts/download-binaries.sh
xcodebuild -project FileConverter.xcodeproj -scheme FileConverter -configuration Release -derivedDataPath ./Build
```

## License

GPL v3
