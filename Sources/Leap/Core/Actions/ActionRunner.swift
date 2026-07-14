import Foundation

/// Runs shell commands / scripts for "command" and "script" slot actions.
/// Fire-and-forget: never blocks the hotkey path.
enum ActionRunner {
    static func runCommand(_ command: String) {
        run(script: command, interpreter: "zsh")
    }

    static func runScript(_ body: String, interpreter: String?) {
        run(script: body, interpreter: interpreter ?? "zsh")
    }

    private static func run(script: String, interpreter: String) {
        let process = Process()
        // `env` resolves the interpreter on PATH (zsh, bash, python3, …).
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [interpreter, "-lc", script]
        do {
            try process.run()
            Log.action.info("ran \(interpreter) action")
        } catch {
            Log.action.error("action failed: \(error.localizedDescription)")
        }
    }
}
