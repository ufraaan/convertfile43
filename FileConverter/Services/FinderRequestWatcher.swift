import Foundation

final class FinderRequestWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let handler: (FinderConversionRequest) -> Void

    init(handler: @escaping (FinderConversionRequest) -> Void) {
        self.handler = handler
        startWatching()
    }

    deinit {
        source?.cancel()
    }

    private func startWatching() {
        // Will watch the App Group shared container for incoming request files
        // from the Finder Sync Extension
    }
}
