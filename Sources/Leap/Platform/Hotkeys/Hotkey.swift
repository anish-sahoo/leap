import Carbon.HIToolbox

/// Parses a combo string like "alt+shift+3" into a Carbon keycode + modifier mask.
struct Hotkey {
    let keyCode: UInt32
    let modifiers: UInt32

    static func parse(_ string: String) -> Hotkey? {
        let parts = string.lowercased()
            .split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }

        var modifiers: UInt32 = 0
        var keyToken: String?

        for part in parts {
            switch part {
            case "alt", "opt", "option": modifiers |= UInt32(optionKey)
            case "cmd", "command": modifiers |= UInt32(cmdKey)
            case "ctrl", "control": modifiers |= UInt32(controlKey)
            case "shift": modifiers |= UInt32(shiftKey)
            default: keyToken = part
            }
        }

        guard let token = keyToken, let code = keyCode(for: token) else { return nil }
        return Hotkey(keyCode: code, modifiers: modifiers)
    }

    /// Step 1 supports the digit row; extend with letters/fn-keys as needed.
    private static func keyCode(for token: String) -> UInt32? {
        let digits: [String: Int] = [
            "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
            "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
            "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        ]
        if let code = digits[token] {
            return UInt32(code)
        }
        return nil
    }
}
