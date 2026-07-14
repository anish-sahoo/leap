import AppKit
import Carbon.HIToolbox
import Logging

/// Registers global hotkeys via Carbon's RegisterEventHotKey (no special
/// permission needed, unlike a CGEventTap). `@MainActor` because Carbon delivers
/// hotkey events on the main run loop.
@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var handlers: [UInt32: @MainActor () -> Void] = [:]
    private var refs: [EventHotKeyRef?] = []
    private var nextID: UInt32 = 1
    private var installed = false

    private init() {}

    func start() {
        guard !installed else { return }
        installed = true

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        // Non-capturing closure so it's a valid @convention(c) callback; Carbon
        // runs it on the main thread, so assuming main-actor isolation is safe.
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                let id = hkID.id
                MainActor.assumeIsolated {
                    HotkeyManager.shared.fire(id: id)
                }
                return noErr
            },
            1,
            &spec,
            nil,
            nil
        )
    }

    /// Register one combo. Returns false if the OS refused (e.g. already taken).
    @discardableResult
    func register(_ hotkey: Hotkey, handler: @escaping @MainActor () -> Void) -> Bool {
        let id = nextID
        nextID += 1

        let hkID = EventHotKeyID(signature: OSType(0x4C45_4150) /* 'LEAP' */, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiers,
            hkID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, ref != nil else {
            Log.hotkeys.error("failed to register (status \(status))")
            return false
        }
        handlers[id] = handler
        refs.append(ref)
        return true
    }

    func reset() {
        for ref in refs where ref != nil {
            UnregisterEventHotKey(ref)
        }
        refs.removeAll()
        handlers.removeAll()
        nextID = 1
    }

    private func fire(id: UInt32) {
        handlers[id]?()
    }
}
