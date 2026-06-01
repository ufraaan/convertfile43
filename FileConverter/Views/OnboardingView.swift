import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.left.arrow.right.square")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to File Converter")
                .font(.largeTitle)
                .bold()

            Text("Convert files with a single right-click in Finder.")

            VStack(alignment: .leading, spacing: 12) {
                OnboardingStep(number: 1, text: "Open System Settings → Privacy & Security → Extensions")
                OnboardingStep(number: 2, text: "Enable \"File Converter Finder Sync\" under Finder Extensions")
                OnboardingStep(number: 3, text: "Right-click any file in Finder and choose \"Convert with File Converter\"")
            }
            .padding()

            Button("Open Extensions Preferences") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.extensions")!)
            }
            .buttonStyle(.borderedProminent)

            Button("Get Started") {
                hasLaunchedBefore = true
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 500)
    }
}

struct OnboardingStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .bold()
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))
                .foregroundStyle(.white)

            Text(text)
                .font(.body)
        }
    }
}
