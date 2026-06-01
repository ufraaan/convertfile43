import Foundation
import SwiftUI

@Observable
final class MainViewModel {
    var isTargeted = false
    var selectedPreset: ConversionPreset?
    var showingFilePicker = false

    func handleDroppedURLs(_ urls: [URL], orchestrator: ConversionOrchestrator, settings: AppSettings) {
        let preset = selectedPreset ?? settings.presets.first!
        for url in urls where preset.inputExtensions.contains(url.pathExtension.lowercased()) {
            orchestrator.addJob(inputURL: url, preset: preset)
        }
    }

    func handleSelectedURLs(_ urls: [URL], orchestrator: ConversionOrchestrator, settings: AppSettings) {
        let preset = selectedPreset ?? settings.presets.first!
        for url in urls where preset.inputExtensions.contains(url.pathExtension.lowercased()) {
            orchestrator.addJob(inputURL: url, preset: preset)
        }
    }
}
