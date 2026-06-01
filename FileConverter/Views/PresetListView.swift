import SwiftUI

struct PresetListView: View {
    @Environment(AppSettings.self) private var settings
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            ForEach(settings.presets) { preset in
                HStack {
                    VStack(alignment: .leading) {
                        Text(preset.name)
                            .font(.body)

                        HStack {
                            Text(preset.outputType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.secondary)
                                .font(.caption)

                            Text(preset.inputExtensions.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    if !preset.isBuiltIn {
                        Button("Edit") {
                            viewModel.editPreset(preset)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)

                        Button("Delete") {
                            viewModel.deletePreset(preset, settings: settings)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 4)
            }
            .onMove { from, to in
                settings.presets.move(fromOffsets: from, toOffset: to)
            }
        }
        .sheet(isPresented: $viewModel.showingPresetEditor) {
            if let preset = viewModel.editingPreset {
                PresetEditorView(preset: preset, isEditing: viewModel.isEditing) { updatedPreset in
                    viewModel.savePreset(updatedPreset, settings: settings)
                }
            }
        }
    }
}
