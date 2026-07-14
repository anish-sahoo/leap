import Foundation
import Logging

// swift-log setup. Two backends: a pretty, colored stdout handler (for
// `swift run`) and the in-app console window (ConsoleLogHandler -> LogStore).
// Call bootstrapLogging() once, before anything logs.

func bootstrapLogging() {
    LoggingSystem.bootstrap { label in
        MultiplexLogHandler([
            PrettyLogHandler(label: label),
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

// MARK: - Stdout (pretty, colored)

/// Colored, human-readable stdout handler:  `12:34:56 INF [window]  message`.
/// Colors are emitted only when stdout is a TTY and NO_COLOR is unset.
struct PrettyLogHandler: LogHandler {
    let label: String
    var logLevel: Logger.Level = .debug
    var metadata: Logger.Metadata = [:]

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    private static let colorEnabled =
        isatty(STDOUT_FILENO) != 0 && ProcessInfo.processInfo.environment["NO_COLOR"] == nil

    func log(event: LogEvent) {
        let subsystem = label.hasPrefix("leap.") ? String(label.dropFirst("leap.".count)) : label
        let time = Self.timestamp()
        let level = event.level

        let line = if Self.colorEnabled {
            "\(ANSI.dim)\(time)\(ANSI.reset) "
                + "\(level.color)\(level.tag)\(ANSI.reset) "
                + "\(ANSI.cyan)\(subsystem)\(ANSI.reset)  "
                + "\(event.message)"
        } else {
            "\(time) \(level.tag) \(subsystem)  \(event.message)"
        }
        print(line)
    }

    private static func timestamp() -> String {
        let parts = Calendar(identifier: .gregorian)
            .dateComponents([.hour, .minute, .second], from: Date())
        return String(
            format: "%02d:%02d:%02d",
            parts.hour ?? 0,
            parts.minute ?? 0,
            parts.second ?? 0
        )
    }
}

// MARK: - In-app console

/// Forwards formatted records to the console window (LogStore). No ANSI — the
/// NSTextView shows plain text.
struct ConsoleLogHandler: LogHandler {
    let label: String
    var logLevel: Logger.Level = .debug
    var metadata: Logger.Metadata = [:]

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(event: LogEvent) {
        let subsystem = label.hasPrefix("leap.") ? String(label.dropFirst("leap.".count)) : label
        let text = "\(event.level.tag) [\(subsystem)] \(event.message)"
        Task { @MainActor in
            LogStore.shared.append(text)
        }
    }
}

// MARK: - ANSI + level styling

private enum ANSI {
    static let reset = "\u{1B}[0m"
    static let dim = "\u{1B}[2m"
    static let red = "\u{1B}[31m"
    static let green = "\u{1B}[32m"
    static let yellow = "\u{1B}[33m"
    static let blue = "\u{1B}[34m"
    static let cyan = "\u{1B}[36m"
    static let gray = "\u{1B}[90m"
    static let boldRed = "\u{1B}[1;31m"
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

    var color: String {
        switch self {
        case .trace, .debug: ANSI.gray
        case .info: ANSI.green
        case .notice: ANSI.blue
        case .warning: ANSI.yellow
        case .error: ANSI.red
        case .critical: ANSI.boldRed
        }
    }
}
