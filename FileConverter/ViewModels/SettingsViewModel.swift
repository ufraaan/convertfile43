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
        settings.presets.append(newPreset)
        editingPreset = newPreset
        isEditing = false
        showingPresetEditor = true
    }

    func editPreset(_ preset: ConversionPreset) {
        editingPreset = preset
        isEditing = true
        showingPresetEditor = true
    }

    func deletePreset(_ preset: ConversionPreset, settings: AppSettings) {
        guard !preset.isBuiltIn else { return }
        settings.presets.removeAll { $0.id == preset.id }
    }

    func save(settings: AppSettings) {
        PresetStore.save(settings.presets)
    }
}
