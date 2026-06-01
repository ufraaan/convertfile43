import Foundation

@Observable
final class AppSettings: @unchecked Sendable {
    var presets: [ConversionPreset]
    var maxParallelJobs: Int
    var revealInFinderOnComplete: Bool
    var playSoundOnComplete: Bool

    init(
        presets: [ConversionPreset] = ConversionPreset.defaultPresets,
        maxParallelJobs: Int = 2,
        revealInFinderOnComplete: Bool = true,
        playSoundOnComplete: Bool = false
    ) {
        self.presets = presets
        self.maxParallelJobs = maxParallelJobs
        self.revealInFinderOnComplete = revealInFinderOnComplete
        self.playSoundOnComplete = playSoundOnComplete
    }
}
