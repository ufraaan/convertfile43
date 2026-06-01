import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ConversionOrchestrator.self) private var orchestrator
    @State private var viewModel = MainViewModel()

    var body: some View {
        VStack(spacing: 0) {
            dropZone
            Divider()
            jobList
        }
        .frame(minWidth: 500, minHeight: 400)
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 36))
                .foregroundStyle(viewModel.isTargeted ? Color.accentColor : Color.secondary)

            Text("Drop files here or click to browse")
                .font(.headline)

            PresetPicker(selectedPreset: $viewModel.selectedPreset, presets: settings.presets)
                .frame(width: 250)

            Button("Choose Files") {
                viewModel.showingFilePicker = true
            }
            .fileImporter(
                isPresented: $viewModel.showingFilePicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    viewModel.handleSelectedURLs(urls, orchestrator: orchestrator, settings: settings)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(viewModel.isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(viewModel.isTargeted ? Color.accentColor : Color.gray.opacity(0.3))
                .padding(12)
        }
        .padding()
    }

    private var jobList: some View {
        Group {
            if orchestrator.jobs.isEmpty {
                ContentUnavailableView(
                    "No Conversions",
                    systemImage: "rectangle.2.swap",
                    description: Text("Drop files above or use the Finder right-click menu")
                )
            } else {
                List {
                    ForEach(orchestrator.jobs) { job in
                        ConversionJobRow(job: job)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            orchestrator.removeJob(id: orchestrator.jobs[index].id)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = await loadURL(from: provider) {
                    urls.append(url)
                }
            }
            await MainActor.run {
                viewModel.handleDroppedURLs(urls, orchestrator: orchestrator, settings: settings)
            }
        }
        return true
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

struct PresetPicker: View {
    @Binding var selectedPreset: ConversionPreset?
    let presets: [ConversionPreset]

    var body: some View {
        Picker("Convert to", selection: $selectedPreset) {
            Text("Select a preset").tag(nil as ConversionPreset?)
            ForEach(presets) { preset in
                Text(preset.name).tag(preset as ConversionPreset?)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}
