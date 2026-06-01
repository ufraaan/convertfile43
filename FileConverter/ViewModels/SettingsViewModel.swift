import Foundation

@Observable
final class SettingsViewModel {
    var showingPresetEditor = false
    var editingPreset: ConversionPreset?
    var isEditing = false

    func addPreset(settings: AppSettings) {
        let newPreset = ConversionPreset(
            name: "New Preset",
            inputExtensions: ["mp4", "mkv"],
            outputType: .mp4,
            settings: .default
        )
        editingPreset = newPreset
        isEditing = false
        showingPresetEditor = true
    }

    func editPreset(_ preset: ConversionPreset) {
        editingPreset = preset
        isEditing = true
        showingPresetEditor = true
    }

    func savePreset(_ preset: ConversionPreset, settings: AppSettings) {
        if let index = settings.presets.firstIndex(where: { $0.id == preset.id }) {
            settings.presets[index] = preset
        } else {
            settings.presets.append(preset)
        }
        PresetStore.save(settings.presets)
    }

    func deletePreset(_ preset: ConversionPreset, settings: AppSettings) {
        guard !preset.isBuiltIn else { return }
        settings.presets.removeAll { $0.id == preset.id }
        PresetStore.save(settings.presets)
    }

    func save(settings: AppSettings) {
        PresetStore.save(settings.presets)
    }
}
