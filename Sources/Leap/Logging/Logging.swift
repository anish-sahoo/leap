import Foundation
import Logging

// swift-log setup for the app.
//
// The logging *facade* is swift-log. We bootstrap two backends:
//   1. StreamLogHandler  — stdout, for `swift run` in a terminal.
//   2. ConsoleLogHandler — feeds the in-app console window (LogStore).
//
// Call `bootstrapLogging()` once, before anything logs.

func bootstrapLogging() {
    LoggingSystem.bootstrap { label in
        MultiplexLogHandler([
            StreamLogHandler.standardOutput(label: label),
            ConsoleLogHandler(label: label),
        ])
    }
}

/// Shared subsystem loggers.
enum Log {
    static let app = Logger(label: "leap.app")
    static let config = Logger(label: "leap.config")
    static let hotkeys = Logger(label: "leap.hotkeys")
    static let login = Logger(label: "leap.login")
    static let window = Logger(label: "leap.window")
    static let action = Logger(label: "leap.action")
}

/// A swift-log backend that forwards formatted records to the in-app console.
struct ConsoleLogHandler: LogHandler {
    let label: String
    var logLevel: Logger.Level = .debug
    var metadata: Logger.Metadata = [:]

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(event: LogEvent) {
        // Short subsystem name (drop the "leap." prefix) for readability.
        let short = label.hasPrefix("leap.")
            ? String(label.dropFirst("leap.".count))
            : label
        let text = "\(event.level.tag) [\(short)] \(event.message)"
        // Handlers may be invoked off the main thread; hop on to touch LogStore.
        Task { @MainActor in
            LogStore.shared.append(text)
        }
    }
}

private extension Logger.Level {
    var tag: String {
        switch self {
        case .trace: "TRC"
        case .debug: "DBG"
        case .info: "INF"
        case .notice: "NOT"
        case .warning: "WRN"
        case .error: "ERR"
        case .critical: "CRT"
        }
    }
}
