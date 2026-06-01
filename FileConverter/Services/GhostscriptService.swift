import Foundation

enum GhostscriptService {
    static func buildPDFToImageArguments(input: String, output: String, resolution: Int = 150) -> [String] {
        [
            "-dNOPAUSE", "-dBATCH",
            "-sDEVICE=png16m",
            "-r\(resolution)",
            "-sOutputFile=\(output)",
            input
        ]
    }

    static func buildImageToPDFArguments(input: String, output: String) -> [String] {
        [
            "-dNOPAUSE", "-dBATCH",
            "-sDEVICE=pdfwrite",
            "-sOutputFile=\(output)",
            input
        ]
    }
}
