import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            PresetListView(viewModel: viewModel)
                .tabItem { Label("Presets", systemImage: "list.bullet") }

            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }

            HelpSettingsView()
                .tabItem { Label("Help", systemImage: "questionmark.circle") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 420)
        .onDisappear {
            viewModel.save(settings: settings)
        }
    }
}

struct GeneralSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var bindableSettings = settings
        Form {
            Section("Conversion") {
                Stepper("Max parallel jobs: \(bindableSettings.maxParallelJobs)", value: $bindableSettings.maxParallelJobs, in: 1...8)
            }

            Section("Completion") {
                Toggle("Reveal in Finder on complete", isOn: $bindableSettings.revealInFinderOnComplete)

                Toggle("Play sound on complete", isOn: $bindableSettings.playSoundOnComplete)
            }

            Section("Bundled Tools") {
                HStack(spacing: 8) {
                    Image(systemName: AppInfo.isFFmpegBundled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(AppInfo.isFFmpegBundled ? .green : .orange)
                    Text(AppInfo.isFFmpegBundled ? "ffmpeg — bundled" : "ffmpeg — not found in app bundle")
                }

                HStack(spacing: 8) {
                    Image(systemName: AppInfo.isFFconvBundled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(AppInfo.isFFconvBundled ? .green : .orange)
                    Text(AppInfo.isFFconvBundled ? "ffconv — bundled" : "ffconv — not found (ffmpeg fallback)")
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct HelpSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to use convertfile43")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                Label("Copy files in Finder (⌘C)", systemImage: "1.circle.fill")
                Label("Click the menu bar icon", systemImage: "2.circle.fill")
                Label("Choose Audio, Video, Images, or Documents", systemImage: "3.circle.fill")
                Label("Pick a preset — converted files appear beside originals", systemImage: "4.circle.fill")
            }

            Text("The app lives in your menu bar. Progress appears on the icon and under Active conversions while a job runs.")
                .foregroundStyle(.secondary)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right.square")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("convertfile43")
                .font(.title2)

            Text("Version \(AppInfo.shortVersion)")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Text("Copy files in Finder (⌘C), then pick a preset from the menu bar.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
