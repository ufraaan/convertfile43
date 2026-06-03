import SwiftUI

struct PresetEditorView: View {
    @State private var editablePreset: ConversionPreset
    let isEditing: Bool
    let onSave: (ConversionPreset) -> Void

    @Environment(\.dismiss) private var dismiss

    init(preset: ConversionPreset, isEditing: Bool, onSave: @escaping (ConversionPreset) -> Void) {
        _editablePreset = State(initialValue: preset)
        self.isEditing = isEditing
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("General") {
                TextField("Preset Name", text: Binding(
                    get: { editablePreset.name },
                    set: { editablePreset.name = $0 }
                ))

                Picker("Output Format", selection: Binding(
                    get: { editablePreset.outputType },
                    set: { editablePreset.outputType = $0 }
                )) {
                    ForEach(OutputType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section("Input Types") {
                TextField("File extensions (comma separated)", text: Binding(
                    get: { editablePreset.inputExtensions.joined(separator: ", ") },
                    set: { editablePreset.inputExtensions = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() } }
                ))
            }

            Section("Settings") {
                if editablePreset.outputType.supportsQuality {
                    VStack(alignment: .leading) {
                        Text("Quality: \(Int(editablePreset.settings.quality ?? 80))")
                        Slider(value: Binding(
                            get: { editablePreset.settings.quality ?? 80 },
                            set: { editablePreset.settings.quality = $0 }
                        ), in: 1...100)
                    }
                }

                if editablePreset.outputType.supportsBitrate {
                    TextField("Bitrate (e.g. 320k)", text: Binding(
                        get: { editablePreset.settings.bitrate ?? "" },
                        set: { editablePreset.settings.bitrate = $0.isEmpty ? nil : $0 }
                    ))
                }

                if editablePreset.outputType.supportsScale {
                    TextField("Scale (e.g. 1920:1080)", text: Binding(
                        get: { editablePreset.settings.scale ?? "" },
                        set: { editablePreset.settings.scale = $0.isEmpty ? nil : $0 }
                    ))
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button(isEditing ? "Save" : "Create") {
                        onSave(editablePreset)
                        dismiss()
                    }
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 500)
    }
}
