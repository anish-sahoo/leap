import AppKit

/// Shows the cheat sheet while the trigger modifier is held alone.
///
/// A short debounce means a quick `⌥1` never flashes the panel, and firing a
/// slot dismisses it immediately (see `dismiss()`). Requires Accessibility /
/// Input Monitoring for the global flags monitor — already needed for window
/// control.
@MainActor
final class CheatsheetController {
    /// Symbols shown for the built-in "open settings" shortcut (see AppDelegate).
    static let settingsSymbols = "⌥,"

    private let panel = CheatsheetPanel()

    private var slots: [Slot] = []
    private var monitors: [Any] = []
    private var pendingShow: DispatchWorkItem?
    private var isShown = false

    // Resolved preferences (defaults; overridden by configure()).
    private var triggerFlags: NSEvent.ModifierFlags = .option
    private var position: CheatsheetPosition = .center
    private var orientation: CheatsheetOrientation = .vertical
    private var debounce: TimeInterval = 0.15

    func start() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            MainActor.assumeIsolated { self?.handleFlags(event) }
        }
        if let global = NSEvent.addGlobalMonitorForEvents(
            matching: [.flagsChanged],
            handler: handler
        ) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged], handler: {
            handler($0)
            return $0
        }) {
            monitors.append(local)
        }
    }

    func update(slots: [Slot]) {
        self.slots = slots
    }

    func configure(_ config: CheatsheetConfig?) {
        triggerFlags = Self.flags(for: config?.trigger)
        position = CheatsheetPosition(config?.position)
        orientation = CheatsheetOrientation(config?.orientation)
        debounce = Double(config?.delayMs ?? 150) / 1000
    }

    /// Present immediately, ignoring the trigger. For development/preview only.
    func previewNow() {
        present()
    }

    /// Cancel a pending show and hide immediately. Called when a slot fires.
    func dismiss() {
        pendingShow?.cancel()
        pendingShow = nil
        if isShown {
            panel.orderOut(nil)
            isShown = false
        }
    }

    private func handleFlags(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == triggerFlags {
            scheduleShow()
        } else {
            dismiss()
        }
    }

    private func scheduleShow() {
        guard !isShown, pendingShow == nil, !slots.isEmpty else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.pendingShow = nil
            self?.present()
        }
        pendingShow = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: work)
    }

    private func present() {
        guard !slots.isEmpty else { return }
        let footer = CheatsheetView.Entry(
            icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil) ??
                NSImage(),
            symbols: Self.settingsSymbols,
            label: "Settings"
        )
        let view = CheatsheetView(slots: slots, orientation: orientation, footer: footer)
        panel.present(view, at: position)
        isShown = true
    }

    private static func flags(for token: String?) -> NSEvent.ModifierFlags {
        switch (token ?? "alt").lowercased() {
        case "cmd", "command": .command
        case "ctrl", "control": .control
        case "shift": .shift
        default: .option
        }
    }
}
