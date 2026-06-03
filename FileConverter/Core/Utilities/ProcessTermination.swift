import Darwin
import Foundation

/// Terminates a process and all of its descendants (e.g. ffconv → ffmpeg).
enum ProcessTermination {
    private static let sigTerm = SIGTERM
    private static let sigKill = SIGKILL

    static func terminateAll(roots: [pid_t], graceSeconds: TimeInterval = 1.0) {
        guard !roots.isEmpty else { return }

        let targets = processTreePIDs(roots: roots)
        LoggerService.info(
            "Sending SIGTERM to process tree (\(targets.count) pid(s), roots: \(roots))",
            component: "ProcessTermination"
        )

        signalAll(targets, sig: sigTerm)
        for root in roots {
            _ = kill(-root, sigTerm)
        }

        waitForExit(pids: targets, graceSeconds: graceSeconds)
        forceKillSurvivors(in: targets, roots: roots)
    }

    /// Kills bundled tool binaries (ffmpeg, ffconv, etc.) even if not tracked (orphans after quit).
    static func terminateBundledConversionTools() {
        let paths = bundledToolExecutablePaths()
        guard !paths.isEmpty else { return }

        var matched: [pid_t] = []
        for pid in listAllPIDs() {
            guard let path = executablePath(for: pid) else { continue }
            if paths.contains(where: { path == $0 || path.hasPrefix($0) }) {
                matched.append(pid)
            }
        }

        guard !matched.isEmpty else { return }
        LoggerService.info(
            "Terminating \(matched.count) bundled-tool process(es): \(matched)",
            component: "ProcessTermination"
        )
        terminateAll(roots: matched, graceSeconds: 0.75)
    }

    static func bundledToolsStillRunning() -> Bool {
        let paths = Set(bundledToolExecutablePaths())
        guard !paths.isEmpty else { return false }
        return listAllPIDs().contains { pid in
            guard let path = executablePath(for: pid) else { return false }
            return paths.contains(path)
        }
    }

    static func bundledToolExecutablePaths() -> [String] {
        ["ffmpeg", "ffconv", "magick", "gs", "potrace"].compactMap {
            Bundle.main.path(forResource: $0, ofType: nil)
        }
    }

    static func isRunning(_ pid: pid_t) -> Bool {
        guard pid > 0 else { return false }
        return kill(pid, 0) == 0
    }

    /// All root PIDs plus any process whose parent chain leads to a root.
    static func processTreePIDs(roots: [pid_t]) -> [pid_t] {
        let rootSet = Set(roots.filter { $0 > 0 })
        guard !rootSet.isEmpty else { return [] }

        var result = rootSet
        let allPIDs = listAllPIDs()
        var parentByPID: [pid_t: pid_t] = [:]
        for pid in allPIDs {
            if let parent = parentPID(of: pid) {
                parentByPID[pid] = parent
            }
        }

        var changed = true
        while changed {
            changed = false
            for (pid, parent) in parentByPID {
                if result.contains(parent), result.insert(pid).inserted {
                    changed = true
                }
            }
        }

        return Array(result)
    }

    private static func signalAll(_ pids: [pid_t], sig: Int32) {
        for pid in pids {
            _ = kill(pid, sig)
        }
    }

    private static func waitForExit(pids: [pid_t], graceSeconds: TimeInterval) {
        let deadline = Date().addingTimeInterval(graceSeconds)
        while Date() < deadline {
            if !pids.contains(where: isRunning) {
                break
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    private static func forceKillSurvivors(in targets: [pid_t], roots: [pid_t]) {
        let survivors = targets.filter(isRunning)
        guard !survivors.isEmpty else { return }

        LoggerService.warning(
            "Sending SIGKILL to \(survivors.count) surviving pid(s): \(survivors)",
            component: "ProcessTermination"
        )
        signalAll(survivors, sig: sigKill)
        for root in roots where isRunning(root) {
            _ = kill(-root, sigKill)
        }
    }

    private static func listAllPIDs() -> [pid_t] {
        var buffer = [pid_t](repeating: 0, count: 8192)
        let bytes = proc_listallpids(&buffer, Int32(buffer.count * MemoryLayout<pid_t>.size))
        guard bytes > 0 else { return [] }
        let count = Int(bytes) / MemoryLayout<pid_t>.size
        return Array(buffer.prefix(count)).filter { $0 > 0 }
    }

    private static func parentPID(of pid: pid_t) -> pid_t? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return pid_t(info.pbi_ppid)
    }

    private static func executablePath(for pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 4096)
        let size = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard size > 0 else { return nil }
        return String(cString: buffer)
    }
}
