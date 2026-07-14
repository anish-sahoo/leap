import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// macOS launch/focus/cycle behavior via the Accessibility API (needs
/// Accessibility permission):
///
///   1. Not running                        -> launch.
///   2. Running, no standard windows        -> open a new window (Cmd-N).
///   3. Running, has windows, not frontmost -> focus + raise the front window.
///   4. Already frontmost                   -> cycle to the next window.
@MainActor
final class AXWindowController: WindowSwitching {
    func activate(appAtBundlePath path: String) {
        guard let app = runningApp(bundlePath: path) else {
            launch(bundlePath: path)
            return
        }
        handle(app)
    }

    // MARK: - App lookup / launch

    /// Match the real app (ignore helper/background processes that share a name).
    private func runningApp(bundlePath: String) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first {
            $0.activationPolicy == .regular && $0.bundleURL?.path == bundlePath
        }
    }

    private func launch(bundlePath: String) {
        let url = URL(fileURLWithPath: bundlePath)
        Log.window.info("launching \(bundlePath)")
        NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, error in
            if let error {
                Log.window.error("launch failed for \(bundlePath): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - State machine

    private func handle(_ app: NSRunningApplication) {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        let windows = standardWindows(of: axApp)
        let name = app.localizedName ?? "app"

        if windows.isEmpty {
            Log.window.info("\(name): running, no windows -> new window")
            app.activate()
            openNewWindow()
            return
        }

        let isFrontmost =
            NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier

        if !isFrontmost {
            Log.window.info("\(name): focusing (\(windows.count) windows)")
            app.activate()
            raiseFrontWindow(of: axApp, windows: windows)
            return
        }

        if windows.count == 1 {
            Log.window.debug("\(name): frontmost, single window -> nothing to cycle")
            return
        }

        cycle(of: axApp, windows: windows, app: app)
    }

    private func raiseFrontWindow(of axApp: AXUIElement, windows: [AXUIElement]) {
        if let focused = focusedWindow(of: axApp) {
            raise(focused)
            return
        }
        if let firstVisible = windows.first(where: { !boolValue(of: $0, kAXMinimizedAttribute) }) {
            raise(firstVisible)
            return
        }
        if let first = windows.first {
            raise(first)
        } // all minimized
    }

    private func cycle(of axApp: AXUIElement, windows: [AXUIElement], app: NSRunningApplication) {
        var index = 0
        if let focused = focusedWindow(of: axApp),
           let i = windows.firstIndex(where: { CFEqual($0, focused) }) {
            index = i
        }
        let next = windows[(index + 1) % windows.count]
        Log.window
            .info("\(app.localizedName ?? "app"): cycling to window \((index + 1) % windows.count)")
        app.activate()
        raise(next)
    }

    // MARK: - AX window helpers

    /// Standard (non-panel) windows, sorted by on-screen position so cycle order
    /// is stable even as focusing reorders the z-order-based AX list.
    private func standardWindows(of axApp: AXUIElement) -> [AXUIElement] {
        guard let raw = copyValue(of: axApp, kAXWindowsAttribute) as? [AXUIElement] else {
            return []
        }
        let standard = raw.filter { window in
            guard let subrole = copyValue(of: window, kAXSubroleAttribute) as? String else {
                return true
            }
            return subrole == (kAXStandardWindowSubrole as String)
        }
        return standard.sorted { lhs, rhs in
            let a = position(of: lhs) ?? .zero
            let b = position(of: rhs) ?? .zero
            return a.x != b.x ? a.x < b.x : a.y < b.y
        }
    }

    private func focusedWindow(of axApp: AXUIElement) -> AXUIElement? {
        guard let value = copyValue(of: axApp, kAXFocusedWindowAttribute),
              CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }
        // swiftlint:disable:next force_cast
        return (value as! AXUIElement)
    }

    private func raise(_ window: AXUIElement) {
        if boolValue(of: window, kAXMinimizedAttribute) {
            AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        }
        AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }

    private func openNewWindow() {
        // The app was just activated; give it a beat, then send Cmd-N.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.sendCommandN()
        }
    }

    private func sendCommandN() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let key = CGKeyCode(kVK_ANSI_N)
        let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // MARK: - Low-level AX accessors

    private func copyValue(of element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success
            ? value : nil
    }

    private func boolValue(of element: AXUIElement, _ attribute: String) -> Bool {
        (copyValue(of: element, attribute) as? Bool) ?? false
    }

    private func position(of window: AXUIElement) -> CGPoint? {
        guard let value = copyValue(of: window, kAXPositionAttribute),
              CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }
        var point = CGPoint.zero
        // swiftlint:disable:next force_cast
        return AXValueGetValue(value as! AXValue, .cgPoint, &point) ? point : nil
    }
}
