import Foundation

/// Pure, OS-agnostic config model that drives the whole app.
struct Config: Codable {
    var version: Int
    var slots: [Slot]

    /// Seeded from the Hammerspoon prototype so there's something to press on
    /// first launch.
    static let starter = Config(
        version: 1,
        slots: [
            Slot(
                id: "chrome",
                hotkey: "alt+1",
                label: "Chrome",
                action: .init(type: "app", target: "/Applications/Google Chrome.app")
            ),
            Slot(
                id: "ghostty",
                hotkey: "alt+2",
                label: "Ghostty",
                action: .init(type: "app", target: "/Applications/Ghostty.app")
            ),
            Slot(
                id: "cmux",
                hotkey: "alt+3",
                label: "cmux",
                action: .init(type: "app", target: "/Applications/cmux.app")
            ),
            Slot(
                id: "vscode",
                hotkey: "alt+4",
                label: "VS Code",
                action: .init(type: "app", target: "/Applications/Visual Studio Code.app")
            ),
            Slot(
                id: "zed",
                hotkey: "alt+5",
                label: "Zed",
                action: .init(type: "app", target: "/Applications/Zed.app")
            ),
        ]
    )
}

struct Slot: Codable, Identifiable {
    var id: String
    /// Full combo string, e.g. "alt+1", "cmd+shift+k". Parsed by Hotkey.parse.
    var hotkey: String
    var label: String
    var action: SlotAction
}

struct SlotAction: Codable {
    var type: String // "app" | "command" | "script"
    var target: String? // app bundle path (for "app") or command line (for "command")
    var body: String? // script body (for "script")
    var interpreter: String? // "zsh" | "bash" | ... (for "script"); defaults to zsh
}
