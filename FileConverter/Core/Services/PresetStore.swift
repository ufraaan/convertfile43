import Foundation

enum PresetStore {
    static func load() -> [ConversionPreset] {
        ConversionPreset.defaultPresets
    }
}
