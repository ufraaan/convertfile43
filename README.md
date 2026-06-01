# File Converter — macOS

A macOS-native file conversion app with Finder right-click integration. Convert audio, video, images, PDFs, and Office documents — directly from the Finder context menu.

Inspired by [FileConverter](https://github.com/Tichau/FileConverter) for Windows.

## Architecture

```
FileConverter.app
├── Main App (SwiftUI)                        # Settings, presets, conversion queue, progress UI
├── Contents/PlugIns/FileConverterFinderSync.appex  # FIFinderSync → right-click menu
└── Contents/Resources/
    ├── ffmpeg                                # Audio/video conversion
    ├── magick                                # Image conversion
    └── gs                                    # PDF processing (Ghostscript)
```

**Pattern:** Finder Sync Extension → IPC (App Group file) → Main app processes conversion → Notification.

## Tech Stack

| Component | Choice |
|---|---|
| Language | Swift 6 |
| UI Framework | SwiftUI + @Observable (macOS 14+) |
| Min. macOS | 13 Ventura |
| Right-click | Finder Sync Extension (`FIFinderSync`) |
| IPC | App Group shared container (JSON files) |
| Audio/Video | Bundled ffmpeg universal binary |
| Images | Bundled ImageMagick (magick) universal binary |
| PDF | Bundled Ghostscript (gs) universal binary |
| Office docs | LibreOffice headless (detected at runtime) |
| Distribution | Signed + notarized DMG (outside App Store) |
| Auto-update | Sparkle |

## Project Structure

```
FileConverter/
├── FileConverter.xcodeproj
├── Project.swift                           # XcodeGen manifest
│
├── FileConverter/                          # Main app target
│   ├── FileConverterApp.swift              # @main entry
│   ├── Info.plist
│   ├── Models/
│   │   ├── OutputType.swift
│   │   ├── ConversionState.swift
│   │   ├── ConversionJob.swift
│   │   ├── ConversionPreset.swift
│   │   ├── ConversionSettings.swift
│   │   └── AppSettings.swift
│   ├── Services/
│   │   ├── ConversionOrchestrator.swift
│   │   ├── FFmpegService.swift
│   │   ├── ImageMagickService.swift
│   │   ├── GhostscriptService.swift
│   │   ├── LibreOfficeService.swift
│   │   ├── PresetStore.swift
│   │   ├── FinderRequestWatcher.swift
│   │   └── NotificationService.swift
│   ├── ViewModels/
│   │   ├── MainViewModel.swift
│   │   ├── SettingsViewModel.swift
│   │   └── ConversionJobViewModel.swift
│   ├── Views/
│   │   ├── MainView.swift
│   │   ├── ConversionJobRow.swift
│   │   ├── SettingsView.swift
│   │   ├── PresetEditorView.swift
│   │   ├── PresetListView.swift
│   │   ├── HelpView.swift
│   │   └── OnboardingView.swift
│   ├── Utilities/
│   │   ├── ProcessRunner.swift
│   │   ├── BundlePaths.swift
│   │   └── Localizable.swift
│   └── Resources/
│       ├── Assets.xcassets/
│       ├── Localizable.xcstrings
│       └── Settings.default.json
│
├── FinderSyncExtension/                    # Extension target
│   ├── FinderSync.swift
│   ├── Info.plist
│   └── Entitlements.plist
│
├── Middleware/
│   ├── binaries/                           # Universal2 binaries (copied into .app)
│   └── Scripts/download-binaries.sh
│
└── Installer/create-dmg.sh
```

## Data Flow

```
User right-clicks file in Finder
  └─► Finder loads FileConverterFinderSync.appex
       └─► Extension reads presets from App Group JSON cache
            └─► Builds "Convert with FileConverter ▸" submenu
                 └─► User clicks preset
                      └─► Extension writes request JSON to App Group shared dir
                           └─► Main app's FinderRequestWatcher detects file
                                └─► ConversionOrchestrator queues job
                                     └─► FFmpegService / ImageMagickService / etc. spawns binary
                                          └─► Progress reported back to SwiftUI
                                               └─► On completion: notification + reveal in Finder
```

## Implementation Roadmap

### Phase 1 — Scaffold & Core Models (Days 1-2)
- [ ] Xcode project with two targets (app + extension)
- [ ] Core models: OutputType, ConversionState, ConversionJob, ConversionPreset, AppSettings
- [ ] SwiftUI main window shell with drop zone
- [ ] Basic conversion queue UI

### Phase 2 — Conversion Services (Days 3-5)
- [ ] FFmpegService (audio/video)
- [ ] ImageMagickService (images)
- [ ] GhostscriptService (PDF)
- [ ] ProcessRunner async wrapper
- [ ] Real-time progress reporting

### Phase 3 — Presets (Days 6-7)
- [ ] PresetStore (load/save JSON)
- [ ] Default presets bundled in app
- [ ] Settings UI: list presets, create, edit, delete
- [ ] Preset → conversion pipeline

### Phase 4 — Finder Integration (Days 8-10)
- [ ] Finder Sync Extension (right-click menu)
- [ ] App Group shared container setup
- [ ] IPC: extension writes request → main app reads
- [ ] Onboarding screen for extension activation

### Phase 5 — Document Conversion (Day 11)
- [ ] LibreOffice headless detection
- [ ] LibreOfficeService
- [ ] Presets for doc/ppt/xls → PDF

### Phase 6 — Polish & Ship (Days 12-14)
- [ ] macOS notifications on completion
- [ ] Error handling with user-friendly messages
- [ ] Dark mode support
- [ ] Binary bundling script
- [ ] Code signing + notarization
- [ ] DMG creation
- [ ] Sparkle auto-update setup
- [ ] GitHub release workflow

## Building

```bash
# Prerequisites: Xcode 16+, macOS 14+
# Download middleware binaries
./Middleware/Scripts/download-binaries.sh

# Build
xcodebuild -project FileConverter.xcodeproj -scheme FileConverter -configuration Release

# Package
./Installer/create-dmg.sh
```

## Conversion Capabilities

### Audio
| Input | → | Output |
|---|---|---|
| mp3, wav, flac, ogg, m4a, wma | → | MP3, AAC, FLAC, OGG, WAV, Opus |

Controls: bitrate, sample rate, channels, encoding mode

### Video
| Input | → | Output |
|---|---|---|
| mp4, mkv, avi, mov, webm, ogv | → | MP4, MKV, AVI, WebM, OGV |

Controls: quality, scale, rotation, fps, encoding speed

### Images
| Input | → | Output |
|---|---|---|
| jpg, png, webp, avif, bmp, tiff, gif | → | JPG, PNG, WebP, AVIF, ICO, GIF |

Controls: quality, scale, rotation

### Documents
| Input | → | Output |
|---|---|---|
| pdf | → | JPG, PNG |
| doc/docx/odt | → | PDF |
| ppt/pptx/odp | → | PDF |
| xls/xlsx/ods | → | PDF |

### Special
- Video → Animated GIF
- CD audio extraction (cda → flac/ogg/mp3) — via ffmpeg
- Bulk batch conversion
