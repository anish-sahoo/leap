import Foundation

/// In-memory ring buffer backing the console window; fed by `ConsoleLogHandler`
/// (see Logging.swift), not written to directly.
@MainActor
final class LogStore {
    static let shared = LogStore()

    private(set) var lines: [String] = []
    private let maxLines = 2000

    /// Live sink — the console window sets this to receive appended lines.
    var onAppend: ((String) -> Void)?

    private init() {}

    func append(_ line: String) {
        lines.append(line)
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
        onAppend?(line)
    }

    func clear() {
        lines.removeAll()
        onAppend?("")
    }
}
