<div align="center">
  <img src="docs/readme-hero.gif" alt="convertfile43" width="480" style="border-radius: 12px;">
  <h1>convertfile43</h1>
  <p >Convert audio, video, images, and documents from your menu bar.</p>
  <p>
    <img src="https://img.shields.io/badge/macOS-14%2B-1d1d1f?logo=apple&style=flat" alt="macOS 14+">
    <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&style=flat" alt="Swift 6.0">
    <img src="https://img.shields.io/badge/Version-0.1.2-1d1d1f?style=flat" alt="Version 0.1.2">
    <img src="https://img.shields.io/badge/License-GPL_v3-1d1d1f?style=flat" alt="GPL v3">
  </p>
</div>

## how it works

copy some files in finder (⌘C), click the menu bar icon, pick a format under audio, video, image, or document. that's it - converted files show up right next to the originals.

no windows, no drag-and-drop, nothing to configure. just the menu bar.

## features

menu bar only, no dock icon. stays out of your way.
batch conversion - copy dozens of files, convert all at once.
comes with ffmpeg, ImageMagick, and Ghostscript bundled in.
with LibreOffice, handles Word, Excel, and PowerPoint too.
macOS notification when a conversion finishes.

## requirements

macOS 14 (sonoma) or newer.

## installation

download the latest .dmg from the [releases page](https://github.com/ufraaan/convertfile43/releases/latest), open it, and drag convertfile43 to your Applications folder. launch it and look for the icon in your menu bar.

the app is unsigned so macOS might show a warning the first time. just right-click it and select Open.

## supported formats

| Category | Output formats | Engine |
|---|---|---|
| Audio | MP3, AAC, FLAC, OGG, WAV | ffmpeg |
| Video | MP4, MKV, AVI, WebM, OGV, GIF | ffmpeg |
| Image | JPG, PNG, WebP, AVIF, ICO | ImageMagick |
| Document | PDF | ImageMagick, Ghostscript, LibreOffice |
| Office* | PDF | LibreOffice |

office documents (doc, docx, xls, xlsx, ppt, pptx, odt, odp, ods) need LibreOffice installed.

## building from source

```bash
brew install xcodegen
xcodegen generate
./Middleware/Scripts/download-binaries.sh
xcodebuild -project convertfile43.xcodeproj -scheme convertfile43 -configuration Release -derivedDataPath ./Build
```

## acknowledgments

this app wouldn't work without the incredible open source tools it wraps around. [ffmpeg](https://ffmpeg.org) handles all audio and video conversion. [ImageMagick](https://imagemagick.org) does the image processing. [Ghostscript](https://ghostscript.com) helps with PDFs. and [LibreOffice](https://www.libreoffice.org) powers the office document conversion. huge thanks to the maintainers and contributors of these projects.

## license

GPL v3 - see [LICENSE](LICENSE)
