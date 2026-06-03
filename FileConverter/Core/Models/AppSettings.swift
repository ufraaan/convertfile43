import Foundation

@Observable
final class AppSettings: @unchecked Sendable {
    var presets: [ConversionPreset]
    var maxParallelJobs: Int
    var revealInFinderOnComplete: Bool
    var playSoundOnComplete: Bool

    init(
        presets: [ConversionPreset] = PresetStore.load(),
        maxParallelJobs: Int = AppSettingsDefaults.maxParallelJobs,
        revealInFinderOnComplete: Bool = AppSettingsDefaults.revealInFinderOnComplete,
        playSoundOnComplete: Bool = AppSettingsDefaults.playSoundOnComplete
    ) {
        self.presets = presets
        self.maxParallelJobs = maxParallelJobs
        self.revealInFinderOnComplete = revealInFinderOnComplete
        self.playSoundOnComplete = playSoundOnComplete
    }

    func saveGeneralPreferences() {
        AppSettingsDefaults.save(
            maxParallelJobs: maxParallelJobs,
            revealInFinderOnComplete: revealInFinderOnComplete,
            playSoundOnComplete: playSoundOnComplete
        )
    }
}

private enum AppSettingsDefaults {
    private static let maxParallelJobsKey = "maxParallelJobs"
    private static let revealInFinderOnCompleteKey = "revealInFinderOnComplete"
    private static let playSoundOnCompleteKey = "playSoundOnComplete"

    static var maxParallelJobs: Int {
        let value = UserDefaults.standard.integer(forKey: maxParallelJobsKey)
        return value == 0 ? 2 : min(max(value, 1), 8)
    }

    static var revealInFinderOnComplete: Bool {
        guard UserDefaults.standard.object(forKey: revealInFinderOnCompleteKey) != nil else {
            return true
        }
        return UserDefaults.standard.bool(forKey: revealInFinderOnCompleteKey)
    }

    static var playSoundOnComplete: Bool {
        UserDefaults.standard.object(forKey: playSoundOnCompleteKey) != nil
            ? UserDefaults.standard.bool(forKey: playSoundOnCompleteKey)
            : true
    }

    static func save(maxParallelJobs: Int, revealInFinderOnComplete: Bool, playSoundOnComplete: Bool) {
        UserDefaults.standard.set(maxParallelJobs, forKey: maxParallelJobsKey)
        UserDefaults.standard.set(revealInFinderOnComplete, forKey: revealInFinderOnCompleteKey)
        UserDefaults.standard.set(playSoundOnComplete, forKey: playSoundOnCompleteKey)
    }
}
