import AppKit
import ApplicationServices

/// Accessibility (AX) permission helpers. Controlling other apps' windows
/// requires the user to grant Accessibility access in System Settings.
enum Accessibility {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Returns current trust; if untrusted, prompts the user (system dialog).
    @discardableResult
    static func requestIfNeeded() -> Bool {
        // Literal value of kAXTrustedCheckOptionPrompt (a global var that strict
        // concurrency won't let us reference directly).
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Deep-link to the Accessibility pane of System Settings.
    static func openSettings() {
        if let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
