/// Routes a slot's action to the right subsystem. This is the domain glue
/// between config and the platform layer: it depends on the `WindowSwitching`
/// protocol, not on any macOS API directly.
@MainActor
final class ActionDispatcher {
    private let windows: WindowSwitching

    init(windows: WindowSwitching) {
        self.windows = windows
    }

    func perform(_ action: SlotAction, label: String) {
        switch action.type {
        case "app":
            guard let path = action.target else {
                Log.action.warning("'\(label)': app action missing target")
                return
            }
            windows.activate(appAtBundlePath: path)

        case "command":
            guard let command = action.target else {
                Log.action.warning("'\(label)': command action missing target")
                return
            }
            ActionRunner.runCommand(command)

        case "script":
            if let body = action.body, !body.isEmpty {
                ActionRunner.runScript(body, interpreter: action.interpreter)
            } else if let path = action.target, !path.isEmpty {
                ActionRunner.runScriptFile(atPath: path, interpreter: action.interpreter)
            } else {
                Log.action.warning("'\(label)': script action needs a 'body' or a 'target' path")
            }

        default:
            Log.action.warning("'\(label)': unknown action type '\(action.type)'")
        }
    }
}
