import AppKit
import Testing
@testable import Leap

/// Renders the cheat-sheet content to a PNG for visual inspection during
/// development. No-op unless LEAP_RENDER_OUT is set, so CI skips it.
/// The live NSVisualEffectView backdrop blur only exists on-screen; this
/// approximates it with a translucent dark panel behind the real content.
@Suite(.serialized)
struct CheatsheetRenderTests {
    @MainActor
    @Test func renderPNG() throws {
        guard let outPath = ProcessInfo.processInfo.environment["LEAP_RENDER_OUT"] else { return }

        let settings = CheatsheetView.Entry(
            icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil) ?? NSImage(),
            symbols: CheatsheetController.settingsSymbols,
            label: "Settings"
        )
        let slots = Config.starter.slots + [
            Slot(id: "btop", hotkey: "alt+6", label: "btop",
                 action: .init(type: "script", body: "btop")),
            Slot(id: "say", hotkey: "alt+7", label: "Say Hi",
                 action: .init(type: "command", target: "say hi")),
        ]
        let view = CheatsheetView(
            slots: slots,
            orientation: .vertical,
            footer: settings,
            onSelect: { _ in },
            onSettings: {}
        )
        view.appearance = NSAppearance(named: .darkAqua)
        view.layoutSubtreeIfNeeded()
        let size = view.fittingSize
        view.frame = NSRect(origin: .zero, size: size)
        view.layoutSubtreeIfNeeded()

        let margin: CGFloat = 48
        let canvas = NSSize(width: size.width + margin * 2, height: size.height + margin * 2)

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(canvas.width), pixelsHigh: Int(canvas.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        let ctx = NSGraphicsContext(bitmapImageRep: rep)!

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        NSAppearance(named: .darkAqua)?.performAsCurrentDrawingAppearance {
            // Desktop-ish gradient backdrop.
            NSGradient(
                starting: NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.24, alpha: 1),
                ending: NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.12, alpha: 1)
            )!.draw(in: NSRect(origin: .zero, size: canvas), angle: -90)

            // Approximate the HUD material behind the panel.
            let panelRect = NSRect(x: margin, y: margin, width: size.width, height: size.height)
            let panel = NSBezierPath(roundedRect: panelRect, xRadius: 14, yRadius: 14)
            NSColor(calibratedWhite: 0.14, alpha: 0.9).setFill()
            panel.fill()

            // Real content on top.
            let viewRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
            view.cacheDisplay(in: view.bounds, to: viewRep)
            viewRep.draw(in: panelRect)
        }
        NSGraphicsContext.restoreGraphicsState()

        let png = rep.representation(using: .png, properties: [:])!
        try png.write(to: URL(fileURLWithPath: outPath))
        print("WROTE \(outPath)")
    }
}
