import Foundation

final class DocumentController {
    private let appSupportDir: URL
    private let currentFile: URL
    private let historyDir: URL
    private var saveTimer: Timer?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportDir = appSupport.appendingPathComponent("Gauss")
        currentFile = appSupportDir.appendingPathComponent("current.gauss")
        historyDir = appSupportDir.appendingPathComponent("history")

        // Create directories
        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: historyDir, withIntermediateDirectories: true)
    }

    /// Load saved content (returns empty string if no save file)
    func loadCurrent() -> String {
        (try? String(contentsOf: currentFile, encoding: .utf8)) ?? ""
    }

    /// Schedule a debounced save (call on every text change)
    func scheduleSave(content: String) {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.save(content: content)
        }
    }

    /// Save immediately
    func save(content: String) {
        try? content.write(to: currentFile, atomically: true, encoding: .utf8)
    }

    /// Archive current content to history, clear current file, return empty string for new doc
    func archiveAndClear() -> String {
        let current = loadCurrent()
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let filename = "\(formatter.string(from: Date())).gauss"
            let historyFile = historyDir.appendingPathComponent(filename)
            try? current.write(to: historyFile, atomically: true, encoding: .utf8)
        }
        // Clear current file
        save(content: "")
        return ""
    }
}
