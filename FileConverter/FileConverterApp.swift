import SwiftUI

@main
struct FileConverterApp: App {
    @State private var settings = AppSettings()
    @State private var conversionOrchestrator = ConversionOrchestrator(settings: AppSettings())

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(settings)
                .environment(conversionOrchestrator)
                .onAppear {
                    conversionOrchestrator = ConversionOrchestrator(settings: settings)
                    _ = FinderRequestWatcher { [orchestrator = conversionOrchestrator] request in
                        orchestrator.enqueue(request: request)
                    }
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 800, height: 600)

        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .environment(settings)
                .environment(conversionOrchestrator)
        }

        WindowGroup("Help", id: "help") {
            HelpView()
        }
    }
}
