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
        .frame(width: 560, height: 480)
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
                Text("Opens Finder and selects the converted file when a job finishes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Play sound on complete", isOn: $bindableSettings.playSoundOnComplete)
                Text("Plays a short system sound when conversion succeeds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Bundled Tools") {
                Label(
                    AppInfo.isFFmpegBundled ? "ffmpeg — bundled" : "ffmpeg — not found in app bundle",
                    systemImage: AppInfo.isFFmpegBundled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(AppInfo.isFFmpegBundled ? Color.primary : Color.orange)

                Label(
                    AppInfo.isFFconvBundled ? "ffconv — bundled" : "ffconv — not found (ffmpeg fallback)",
                    systemImage: AppInfo.isFFconvBundled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(AppInfo.isFFconvBundled ? Color.primary : Color.orange)
            }
        }
        .formStyle(.grouped)
    }
}

struct HelpSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("How to use convertfile43")
                    .font(.title2.bold())

                Group {
                    Label("Copy files in Finder (⌘C)", systemImage: "1.circle.fill")
                    Label("Click the menu bar icon", systemImage: "2.circle.fill")
                    Label("Choose Audio, Video, Images, or Documents", systemImage: "3.circle.fill")
                    Label("Pick a preset — converted files appear beside originals", systemImage: "4.circle.fill")
                }
                .font(.body)

                Text("The app lives in your menu bar. Progress appears on the icon and under Active conversions while a job runs.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right.square")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("convertfile43")
                .font(.title)

            Text("Version \(AppInfo.shortVersion)")
                .foregroundStyle(.secondary)

            Text("Copy files in Finder (⌘C), then pick a preset from the menu bar.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
