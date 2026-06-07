import SwiftUI

struct PresetListView: View {
    @Environment(AppSettings.self) private var settings
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        List(settings.presets) { preset in
            HStack(spacing: 12) {
                Image(systemName: iconName(for: preset.outputType.category))
                    .foregroundStyle(.secondary)
                    .font(.title3)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.body)

                    Text("\(preset.outputType.displayName)  ·  \(preset.inputExtensions.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func iconName(for category: OutputType.Category) -> String {
        switch category {
        case .audio: "waveform"
        case .video: "film"
        case .image: "photo"
        case .document: "doc"
        }
    }
}
