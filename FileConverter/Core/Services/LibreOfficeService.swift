import Foundation

enum LibreOfficeService {
    static var isAvailable: Bool {
        FileManager.default.fileExists(atPath: "/Applications/LibreOffice.app")
    }

    static var executablePath: String {
        "/Applications/LibreOffice.app/Contents/MacOS/soffice"
    }

    static func buildConvertToPDFArguments(input: String, outputDir: String) -> [String] {
        [
            "--headless",
            "--convert-to", "pdf",
            "--outdir", outputDir,
            input
        ]
    }
}
