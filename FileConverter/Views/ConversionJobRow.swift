import SwiftUI

struct ConversionJobRow: View {
    let job: ConversionJob
    @State private var viewModel: ConversionJobViewModel?

    var body: some View {
        let vm = viewModel ?? ConversionJobViewModel(job: job)
        HStack(spacing: 12) {
            Image(systemName: vm.statusIcon)
                .foregroundStyle(color(for: vm.statusColor))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(job.fileName)
                    .font(.body)
                    .lineLimit(1)

                Text("→ \(job.outputFileName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if job.state == .running || job.state == .queued {
                    ProgressView(value: job.progress, total: 100)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 200)
                }

                if job.state == .failed, let error = job.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }

            Spacer()

            if job.state == .queued || job.state == .running {
                Button("Cancel") {
                    // Cancel action
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            if job.state == .completed {
                Button("Reveal") {
                    NSWorkspace.shared.activateFileViewerSelecting([job.outputURL])
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4)
        .onAppear { viewModel = vm }
    }

    private func color(for name: String) -> Color {
        switch name {
        case "green": return .green
        case "red": return .red
        case "blue": return .blue
        case "orange": return .orange
        default: return .gray
        }
    }
}
