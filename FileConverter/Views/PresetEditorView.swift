import SwiftUI

struct PresetEditorView: View {
    @Bindable var preset: ConversionPreset
    let isEditing: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some Form {
        Form {
            Section("General") {
                TextField("Preset Name", text: $preset.name)

                Picker("Output Format", selection: $preset.outputType) {
                    ForEach(OutputType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section("Input Types") {
                TextField("File extensions (comma separated)", text: Binding(
                    get: { preset.inputExtensions.joined(separator: ", ") },
                    set: { preset.inputExtensions = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() } }
                ))
            }

            Section("Settings") {
                if preset.outputType.supportsQuality {
                    VStack(alignment: .leading) {
                        Text("Quality: \(Int(preset.settings.quality ?? 80))")
                        Slider(value: Binding(
                            get: { preset.settings.quality ?? 80 },
                            set: { preset.settings.quality = $0 }
                        ), in: 1...100)
                    }
                }

                if preset.outputType.supportsBitrate {
                    TextField("Bitrate (e.g. 320k)", text: Binding(
                        get: { preset.settings.bitrate ?? "" },
                        set: { preset.settings.bitrate = $0.isEmpty ? nil : $0 }
                    ))
                }

                if preset.outputType.supportsScale {
                    TextField("Scale (e.g. 1920:1080)", text: Binding(
                        get: { preset.settings.scale ?? "" },
                        set: { preset.settings.scale = $0.isEmpty ? nil : $0 }
                    ))
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button(isEditing ? "Save" : "Create") {
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
