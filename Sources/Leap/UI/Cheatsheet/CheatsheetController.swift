import AppKit

/// Shows the cheat sheet while the trigger modifier (Option) is held alone.
///
/// A short debounce means a quick `⌥1` never flashes the panel, and firing a
/// slot dismisses it immediately (see `dismiss()`). Requires Accessibility /
/// Input Monitoring for the global flags monitor — already needed for window
/// control.
@MainActor
final class CheatsheetController {
    private let panel = CheatsheetPanel()
    private let debounce = 0.15

    private var slots: [Slot] = []
    private var monitors: [Any] = []
    private var pendingShow: DispatchWorkItem?
    private var isShown = false

    func start() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            MainActor.assumeIsolated { self?.handleFlags(event) }
        }
        // Global fires when another app is frontmost (our usual case); local
        // fires when one of our own windows is key.
        if let global = NSEvent.addGlobalMonitorForEvents(
            matching: [.flagsChanged],
            handler: handler
        ) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(
            matching: [.flagsChanged],
            handler: { event in
                handler(event)
                return event
            }
        ) {
            monitors.append(local)
        }
    }

    func update(slots: [Slot]) {
        self.slots = slots
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
        if flags == .option {
            scheduleShow()
        } else {
            dismiss()
        }
    }

    private func scheduleShow() {
        guard !isShown, pendingShow == nil, !slots.isEmpty else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            pendingShow = nil
            panel.present(slots: slots)
            isShown = true
        }
        pendingShow = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: work)
    }
}
