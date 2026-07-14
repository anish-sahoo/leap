import Foundation
import TOMLKit

/// Validates raw TOML config text: syntax, unknown keys, and semantic rules.
/// Returns a list of human-readable problems; empty means valid.
enum ConfigValidator {
    private static let topKeys: Set<String> =
        ["version", "slots", "cheatsheet", "terminal", "terminalCommand"]
    private static let terminals = Set(TerminalApp.allCases.map(\.rawValue))
    private static let slotKeys: Set<String> = ["id", "hotkey", "label", "action"]
    private static let actionKeys: Set<String> = ["type", "target", "body", "interpreter", "name"]
    private static let cheatsheetKeys: Set<String> = [
        "trigger",
        "position",
        "orientation",
        "delayMs",
    ]
    private static let actionTypes: Set<String> = ["app", "command", "script"]
    private static let triggers: Set<String> =
        ["alt", "option", "opt", "cmd", "command", "ctrl", "control", "shift"]
    private static let positions: Set<String> = [
        "center", "top", "bottom", "left", "right",
        "top-left", "top-right", "bottom-left", "bottom-right",
    ]
    private static let orientations: Set<String> = ["vertical", "horizontal"]

    static func validate(_ text: String) -> [String] {
        let table: TOMLTable
        do {
            table = try TOMLTable(string: text)
        } catch {
            return ["Syntax error: \(concise(error))"]
        }

        var errors = unknownKeyErrors(in: table)
        do {
            let config = try TOMLDecoder().decode(Config.self, from: text)
            errors += semanticErrors(config)
        } catch {
            errors.append("Invalid config: \(concise(error))")
        }
        return errors
    }

    // MARK: - Unknown keys (generic JSON walk)

    private static func unknownKeyErrors(in table: TOMLTable) -> [String] {
        guard let data = table.convert(to: .json).data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        var errors: [String] = []
        errors += unknown(root.keys, allowed: topKeys, scope: "top-level")

        if let slots = root["slots"] as? [[String: Any]] {
            for (index, slot) in slots.enumerated() {
                let scope = "slot #\(index + 1)"
                errors += unknown(slot.keys, allowed: slotKeys, scope: scope)
                if let action = slot["action"] as? [String: Any] {
                    errors += unknown(action.keys, allowed: actionKeys, scope: "\(scope) action")
                }
            }
        }
        if let cheatsheet = root["cheatsheet"] as? [String: Any] {
            errors += unknown(cheatsheet.keys, allowed: cheatsheetKeys, scope: "cheatsheet")
        }
        return errors
    }

    private static func unknown(
        _ keys: some Collection<String>,
        allowed: Set<String>,
        scope: String
    ) -> [String] {
        keys.filter { !allowed.contains($0) }
            .sorted()
            .map { "\(scope): unknown key '\($0)'" }
    }

    // MARK: - Semantics

    private static func semanticErrors(_ config: Config) -> [String] {
        var errors: [String] = []
        if config.slots.isEmpty {
            errors.append("No slots defined")
        }

        var seenHotkeys: Set<String> = []
        for (index, slot) in config.slots.enumerated() {
            let scope = "slot #\(index + 1) (\(slot.id))"
            if slot.id.isEmpty {
                errors.append("\(scope): id is empty")
            }
            if Hotkey.parse(slot.hotkey) == nil {
                errors.append("\(scope): invalid hotkey '\(slot.hotkey)'")
            } else if !seenHotkeys.insert(slot.hotkey.lowercased()).inserted {
                errors.append("\(scope): duplicate hotkey '\(slot.hotkey)'")
            }
            errors += actionErrors(slot.action, scope: scope)
        }
        if let terminal = config.terminal, !terminals.contains(terminal.lowercased()) {
            errors.append("terminal '\(terminal)' is not valid")
        }
        if config.terminal?.lowercased() == "custom", (config.terminalCommand ?? "").isEmpty {
            errors.append("terminal is 'custom' but terminalCommand is empty")
        }
        errors += cheatsheetErrors(config.cheatsheet)
        return errors
    }

    private static func actionErrors(_ action: SlotAction, scope: String) -> [String] {
        guard actionTypes.contains(action.type) else {
            return ["\(scope): unknown action type '\(action.type)'"]
        }
        switch action.type {
        case "app" where (action.target ?? "").isEmpty:
            return ["\(scope): app action needs a 'target' bundle path"]
        case "command" where (action.target ?? "").isEmpty:
            return ["\(scope): command action needs a 'target'"]
        case "script" where (action.body ?? "").isEmpty && (action.target ?? "").isEmpty:
            return ["\(scope): script action needs a 'body' or a 'target' path"]
        default:
            return []
        }
    }

    private static func cheatsheetErrors(_ cheatsheet: CheatsheetConfig?) -> [String] {
        guard let cheatsheet else { return [] }
        var errors: [String] = []
        if let trigger = cheatsheet.trigger, !triggers.contains(trigger.lowercased()) {
            errors.append("cheatsheet.trigger '\(trigger)' is not valid")
        }
        if let position = cheatsheet.position, !positions.contains(position.lowercased()) {
            errors.append("cheatsheet.position '\(position)' is not valid")
        }
        if let orientation = cheatsheet.orientation,
           !orientations.contains(orientation.lowercased()) {
            errors.append("cheatsheet.orientation '\(orientation)' is not valid")
        }
        return errors
    }

    private static func concise(_ error: Error) -> String {
        let text = String(describing: error)
        return text.count > 200 ? String(text.prefix(200)) + "…" : text
    }
}
