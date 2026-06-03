import SwiftUI

struct PresetListView: View {
    @Environment(AppSettings.self) private var settings
    @Bindable var viewModel: SettingsViewModel
    @State private var presetToDelete: ConversionPreset?

    private var builtInPresets: [ConversionPreset] {
        settings.presets.filter { $0.isBuiltIn }
    }

    private var customPresets: [ConversionPreset] {
        settings.presets.filter { !$0.isBuiltIn }
    }

    var body: some View {
        List {
            if !builtInPresets.isEmpty {
                Section("Built-in") {
                    ForEach(builtInPresets) { preset in
                        presetRow(preset)
                    }
                }
            }

            Section("Custom") {
                if customPresets.isEmpty {
                    Text("No custom presets yet. Click + to add one.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(customPresets) { preset in
                        presetRow(preset)
                    }
                    .onMove { from, to in
                        moveCustomPresets(from: from, to: to)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.addPreset(settings: settings)
                } label: {
                    Label("Add Preset", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingPresetEditor) {
            if let preset = viewModel.editingPreset {
                PresetEditorView(preset: preset, isEditing: viewModel.isEditing) { updatedPreset in
                    viewModel.savePreset(updatedPreset, settings: settings)
                }
            }
        }
        .confirmationDialog(
            "Delete preset \"\(presetToDelete?.name ?? "")\"?",
            isPresented: Binding(
                get: { presetToDelete != nil },
                set: { if !$0 { presetToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let preset = presetToDelete {
                    viewModel.deletePreset(preset, settings: settings)
                }
                presetToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                presetToDelete = nil
            }
        }
    }

    @ViewBuilder
    private func presetRow(_ preset: ConversionPreset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(preset.name)
                        .font(.body)
                    if preset.isBuiltIn {
                        Text("Built-in")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }

                Text("\(preset.outputType.displayName) • \(preset.inputExtensions.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !preset.isBuiltIn {
                Button("Edit") {
                    viewModel.editPreset(preset)
                }
                .buttonStyle(.borderless)

                Button("Delete") {
                    presetToDelete = preset
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
    }

    private func moveCustomPresets(from source: IndexSet, to destination: Int) {
        var custom = customPresets
        custom.move(fromOffsets: source, toOffset: destination)
        let builtIn = builtInPresets
        settings.presets = builtIn + custom
        PresetStore.save(settings.presets)
    }
}
