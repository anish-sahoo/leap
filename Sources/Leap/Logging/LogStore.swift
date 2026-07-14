import Foundation

/// In-memory log buffer backing the console/log views; fed by `ConsoleLogHandler`
/// (see Logging.swift). Keeps the most recent lines; the oldest are dropped past
/// the cap.
@MainActor
final class LogStore {
    static let shared = LogStore()

    private(set) var lines: [String] = []
    private let maxLines = 2000
    private var observers: [UUID: (String) -> Void] = [:]

    private init() {}

    /// Observe appended lines. An empty string signals "reload from `lines`"
    /// (sent after a flush or clear). Returns a token for `removeObserver`.
    @discardableResult
    func addObserver(_ callback: @escaping (String) -> Void) -> UUID {
        let token = UUID()
        observers[token] = callback
        return token
    }

    func removeObserver(_ token: UUID) {
        observers[token] = nil
    }

    func append(_ line: String) {
        lines.append(line)
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
            notify("") // trimmed: reload from `lines`
        } else {
            notify(line)
        }
    }

    func clear() {
        lines.removeAll()
        notify("")
    }

    private func notify(_ value: String) {
        for callback in observers.values {
            callback(value)
        }
    }
}
