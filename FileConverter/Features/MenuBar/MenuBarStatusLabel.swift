import SwiftUI

struct MenuBarStatusLabel: View {
    let orchestrator: ConversionOrchestrator

    @State private var doneFlashUntil: Date?
    @State private var refreshToken = 0
    @State private var lastJobsSnapshot = ""

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "rectangle.2.swap")
            statusText
                .font(.system(size: 11, design: .monospaced))
        }
        .id(refreshToken)
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            refreshSnapshot()
        }
        .onAppear {
            updateDoneFlash()
        }
    }

    private func refreshSnapshot() {
        let snapshot = orchestrator.jobs
            .map { "\($0.id.uuidString)|\($0.state)|\($0.progress)|\($0.etaSecondsRemaining ?? -1)|\($0.isIndeterminate)" }
            .joined(separator: ";")
        guard snapshot != lastJobsSnapshot else { return }
        lastJobsSnapshot = snapshot
        refreshToken += 1
        updateDoneFlash()
    }

    @ViewBuilder
    private var statusText: some View {
        if let running = orchestrator.jobs.first(where: { $0.state == .running }) {
            Text(running.statusProgressLabel)
        } else if let until = doneFlashUntil, until > Date() {
            Label("Done", systemImage: "checkmark")
                .labelStyle(.titleOnly)
        } else if orchestrator.jobs.contains(where: { $0.state == .queued }) {
            let count = orchestrator.jobs.filter { $0.state == .queued }.count
            Text(count == 1 ? "•" : "\(count)")
        }
    }

    private func updateDoneFlash() {
        let hasRunning = orchestrator.jobs.contains { $0.state == .running }
        let hasRecentFinish = orchestrator.jobs.contains { $0.state == .completed || $0.state == .failed }
        if !hasRunning && hasRecentFinish {
            doneFlashUntil = Date().addingTimeInterval(3)
        }
    }
}

extension ConversionJob {
    var statusProgressLabel: String {
        switch state {
        case .running where isIndeterminate:
            return "…"
        case .running:
            return "\(Int(progress.rounded()))%"
        default:
            return ""
        }
    }
}
