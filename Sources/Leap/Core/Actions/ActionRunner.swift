import Foundation

/// Runs inline scripts / script files for "script" slot actions.
/// Fire-and-forget: never blocks the hotkey path. ("command" actions run in a
/// terminal — see TerminalLauncher.)
enum ActionRunner {
    static func runScript(_ body: String, interpreter: String?) {
        run(script: body, interpreter: interpreter ?? "zsh")
    }

    /// Run a script file by path. With an interpreter, runs `env <interp> <path>`;
    /// otherwise executes the file directly (respecting its shebang / +x bit).
    static func runScriptFile(atPath path: String, interpreter: String?) {
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        let process = Process()
        if let interpreter, !interpreter.isEmpty {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [interpreter, url.path]
        } else {
            process.executableURL = url
        }
        launch(process, description: "script \(url.lastPathComponent)")
    }

    private static func run(script: String, interpreter: String) {
        let process = Process()
        // `env` resolves the interpreter on PATH (zsh, bash, python3, …).
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [interpreter, "-lc", script]
        launch(process, description: "\(interpreter) action")
    }

    private static func launch(_ process: Process, description: String) {
        do {
            try process.run()
            Log.action.info("ran \(description)")
        } catch {
            Log.action.error("action failed (\(description)): \(error.localizedDescription)")
        }
    }
}
