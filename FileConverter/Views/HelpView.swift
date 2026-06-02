import SwiftUI

struct HelpView: View {
    var body: some View {
        TabView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How to Use convertfile43")
                    .font(.title2)
                    .bold()

                Group {
                    Text("1. Copy files in Finder (Cmd+C)")
                    Text("2. Click the menu bar icon")
                    Text("3. Pick a format under Audio, Video, Image, or Document")
                    Text("4. Converted files appear next to the originals")
                }
                .font(.body)

                Divider()

                Text("The app lives in your menu bar -- no windows needed.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .tabItem { Label("Usage", systemImage: "questionmark.circle") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 450, height: 300)
    }
}
