import Foundation

@Observable
final class SettingsViewModel {
    func save(settings: AppSettings) {
        settings.saveGeneralPreferences()
    }
}
