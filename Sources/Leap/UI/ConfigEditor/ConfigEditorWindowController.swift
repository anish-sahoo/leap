import AppKit

/// Editable raw-TOML config editor. Validates on save (never writes invalid
/// TOML) and reports parse errors inline. On a successful save it calls
/// `onSaved` so the app can re-bind hotkeys.
@MainActor
final class ConfigEditorWindowController: NSWindowController {
    /// Invoked after a valid save so the app can reload bindings.
    var onSaved: (() -> Void)?

    private var textView: NSTextView!
    private var statusLabel: NSTextField!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Edit Config — config.toml"
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.center()
        buildUI()
        reloadFromDisk()
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }
        let barHeight: CGFloat = 44

        // Editor
        let scroll = NSScrollView(frame: NSRect(
            x: 0,
            y: barHeight,
            width: content.bounds.width,
            height: content.bounds.height - barHeight
        ))
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder

        let tv = NSTextView(frame: scroll.bounds)
        tv.isEditable = true
        tv.isRichText = false
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.textContainerInset = NSSize(width: 8, height: 8)
        tv.autoresizingMask = [.width]
        tv.isVerticallyResizable = true
        tv.textContainer?.widthTracksTextView = true
        scroll.documentView = tv
        content.addSubview(scroll)
        textView = tv

        // Bottom bar: [status .... Reload] [Save]
        let bar = NSView(frame: NSRect(x: 0, y: 0, width: content.bounds.width, height: barHeight))
        bar.autoresizingMask = [.width]

        let status = NSTextField(labelWithString: "")
        status.frame = NSRect(x: 12, y: 12, width: content.bounds.width - 220, height: 20)
        status.autoresizingMask = [.width]
        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byTruncatingTail
        bar.addSubview(status)
        statusLabel = status

        let save = NSButton(title: "Save", target: self, action: #selector(save))
        save.frame = NSRect(x: content.bounds.width - 92, y: 7, width: 80, height: 30)
        save.autoresizingMask = [.minXMargin]
        save.keyEquivalent = "\r" // Cmd/Return
        bar.addSubview(save)

        let reload = NSButton(title: "Revert", target: self, action: #selector(reloadFromDisk))
        reload.frame = NSRect(x: content.bounds.width - 180, y: 7, width: 84, height: 30)
        reload.autoresizingMask = [.minXMargin]
        bar.addSubview(reload)

        content.addSubview(bar)
    }

    @objc private func reloadFromDisk() {
        textView.string = ConfigStore.rawText()
        setStatus("Loaded from \(ConfigStore.fileURL.lastPathComponent)", isError: false)
    }

    @objc private func save() {
        do {
            try ConfigStore.writeRaw(textView.string)
            setStatus("Saved ✓  bindings reloaded", isError: false)
            onSaved?()
        } catch {
            setStatus("✗ \(error.localizedDescription)", isError: true)
        }
    }

    private func setStatus(_ text: String, isError: Bool) {
        statusLabel.stringValue = text
        statusLabel.textColor = isError ? .systemRed : .secondaryLabelColor
    }
}
