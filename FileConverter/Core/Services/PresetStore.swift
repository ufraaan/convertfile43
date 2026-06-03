import Foundation

enum PresetStore {
    private static let userDefaultsKey = "customPresets"

    static func load() -> [ConversionPreset] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let presets = try? JSONDecoder().decode([ConversionPreset].self, from: data) else {
            return ConversionPreset.defaultPresets
        }
        return ConversionPreset.defaultPresets + presets
    }

    static func save(_ presets: [ConversionPreset]) {
        let custom = presets.filter { !$0.isBuiltIn }
        guard let data = try? JSONEncoder().encode(custom) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}
