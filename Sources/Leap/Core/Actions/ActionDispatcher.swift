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
            guard let body = action.body else {
                Log.action.warning("'\(label)': script action missing body")
                return
            }
            ActionRunner.runScript(body, interpreter: action.interpreter)

        default:
            Log.action.warning("'\(label)': unknown action type '\(action.type)'")
        }
    }
}
