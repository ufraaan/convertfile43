import SwiftUI

struct HelpView: View {
    var body: some View {
        TabView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How to Use File Converter")
                    .font(.title2)
                    .bold()

                Group {
                    Text("1. Right-click any file in Finder")
                    Text("2. Select \"Convert with File Converter\"")
                    Text("3. Choose a preset from the submenu")
                    Text("4. The app will convert and save the file")
                }
                .font(.body)

                Divider()

                Text("You can also drag and drop files onto the app window.")
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
