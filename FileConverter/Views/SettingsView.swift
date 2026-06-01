import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            PresetListView()
                .tabItem { Label("Presets", systemImage: "list.bullet") }

            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500, height: 400)
        .onDisappear {
            viewModel.save(settings: settings)
        }
    }
}

struct GeneralSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Form {
            Section("Conversion") {
                Stepper("Max parallel jobs: \(settings.maxParallelJobs)", value: $settings.maxParallelJobs, in: 1...8)
            }

            Section("Completion") {
                Toggle("Reveal in Finder on complete", isOn: $settings.revealInFinderOnComplete)
                Toggle("Play sound on complete", isOn: $settings.playSoundOnComplete)
            }
        }
        .formStyle(.grouped)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right.square")
                .font(.system(size: 64))
                .foregroundStyle(.accentColor)

            Text("File Converter")
                .font(.title)

            Text("Version 1.0.0")
                .foregroundStyle(.secondary)

            Text("Convert files with a right-click in Finder.")
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
