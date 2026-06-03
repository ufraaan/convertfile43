import AppKit

@MainActor
enum QuitConfirmation {
    private static let quitWarningMessage = """
    convertfile43 will stop conversions and try to quit ffmpeg and related tools.

    Sometimes ffmpeg keeps running after quit (especially during large video encodes).

    If you still see ffmpeg in Activity Monitor:
    1. Open Activity Monitor (Applications → Utilities → Activity Monitor)
    2. Search for “ffmpeg”
    3. Select the ffmpeg row, then click Stop (⛔) in the toolbar
    4. Choose Force Quit

    The bundled ffmpeg lives inside convertfile43.app → Contents → Resources.
    """

    static func confirmQuit(hasActiveConversion: Bool) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = hasActiveConversion ? .warning : .informational
        alert.messageText = hasActiveConversion
            ? "Quit while converting?"
            : "Quit convertfile43?"
        alert.informativeText = hasActiveConversion
            ? quitWarningMessage
            : "Any background conversion tools will be stopped."
        alert.addButton(withTitle: "Quit Anyway")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    static func showOrphanFFmpegReminder() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "ffmpeg may still be running"
        alert.informativeText = """
        convertfile43 has quit, but ffmpeg was still detected.

        Open Activity Monitor, search for “ffmpeg”, select it, and click Stop (⛔) → Force Quit.

        You can also filter by process path containing “convertfile43.app/Contents/Resources”.
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
