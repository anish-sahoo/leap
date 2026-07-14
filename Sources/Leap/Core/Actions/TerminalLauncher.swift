import AppKit

/// Terminal apps a "command" action can run in.
enum TerminalApp: String, CaseIterable {
    case auto, terminal, iterm2, ghostty, warp, kitty, alacritty, custom

    init(_ raw: String?) {
        self = raw.flatMap { TerminalApp(rawValue: $0.lowercased()) } ?? .auto
    }

    var bundleID: String? {
        switch self {
        case .auto, .custom: nil
        case .terminal: "com.apple.Terminal"
        case .iterm2: "com.googlecode.iterm2"
        case .ghostty: "com.mitchellh.ghostty"
        case .warp: "dev.warp.Warp-Stable"
        case .kitty: "net.kovidgoyal.kitty"
        case .alacritty: "org.alacritty"
        }
    }
}

/// Opens a command in a new terminal window. Terminal.app and iTerm2 use
/// AppleScript; others launch a fresh instance with `open … --args`.
enum TerminalLauncher {
    static func run(_ command: String, in preference: TerminalApp, customTemplate: String? = nil) {
        let terminal = resolve(preference)
        Log.action.info("running command in \(terminal.rawValue)")
        switch terminal {
        case .terminal, .warp:
            runAppleScript(appleTerminalScript(command))
        case .iterm2:
            runAppleScript(itermScript(command))
        case .ghostty, .alacritty:
            openInstance(terminal, args: ["-e", "/bin/zsh", "-lc", command])
        case .kitty:
            openInstance(terminal, args: ["/bin/zsh", "-lc", command])
        case .custom:
            runCustom(command, template: customTemplate)
        case .auto:
            break // resolve() never returns .auto
        }
    }

    // MARK: - Resolution

    private static func resolve(_ preference: TerminalApp) -> TerminalApp {
        if preference == .custom {
            return .custom
        }
        if preference != .auto {
            if isInstalled(preference) {
                return preference
            }
            Log.action.warning("terminal '\(preference.rawValue)' not installed; auto-detecting")
        }
        for candidate in [TerminalApp.ghostty, .iterm2] where isInstalled(candidate) {
            return candidate
        }
        return .terminal // Terminal.app is always present
    }

    private static func isInstalled(_ terminal: TerminalApp) -> Bool {
        guard let id = terminal.bundleID else { return false }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil
    }

    // MARK: - Launch strategies

    private static func openInstance(_ terminal: TerminalApp, args: [String]) {
        guard let id = terminal.bundleID else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", "-b", id, "--args"] + args
        try? process.run()
    }

    private static func runCustom(_ command: String, template: String?) {
        guard let template, !template.isEmpty else {
            Log.action.error("custom terminal selected but terminalCommand is empty")
            return
        }
        let expanded = template.replacingOccurrences(of: "{cmd}", with: command)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", expanded]
        try? process.run()
    }

    private static func runAppleScript(_ script: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    private static func appleTerminalScript(_ command: String) -> String {
        """
        tell application "Terminal"
            activate
            do script "\(escaped(command))"
        end tell
        """
    }

    private static func itermScript(_ command: String) -> String {
        """
        tell application "iTerm"
            activate
            set newWindow to (create window with default profile)
            tell current session of newWindow to write text "\(escaped(command))"
        end tell
        """
    }

    private static func escaped(_ command: String) -> String {
        command.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
