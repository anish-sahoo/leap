import AppKit
import Testing
@testable import Leap

/// Renders the settings tabs to PNGs for visual inspection. No-op unless
/// LEAP_RENDER_DIR is set, so CI skips it.
@Suite(.serialized)
struct SettingsRenderTests {
    @MainActor
    @Test func renderTabs() throws {
        guard let dir = ProcessInfo.processInfo.environment["LEAP_RENDER_DIR"] else { return }

        let form = SettingsFormView(frame: NSRect(x: 0, y: 0, width: 600, height: 460))
        form.load(Config.starter)
        try snapshot(form, to: "\(dir)/settings-form.png")

        let toml = TOMLTabView(frame: NSRect(x: 0, y: 0, width: 600, height: 460))
        toml.setText(try ConfigStore.serialize(Config.starter))
        try snapshot(toml, to: "\(dir)/settings-toml.png")
    }

    @MainActor
    private func snapshot(_ view: NSView, to path: String) throws {
        let window = NSWindow(
            contentRect: view.frame,
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        try rep.representation(using: .png, properties: [:])?
            .write(to: URL(fileURLWithPath: path))
    }
}
