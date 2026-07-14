import AppKit

/// Applies TOML syntax colors to an NSTextStorage in place (preserving the
/// text and cursor). Cheap enough to run on every keystroke for a config file.
enum TOMLHighlighter {
    private static let rules: [(regex: NSRegularExpression, color: NSColor)] = {
        func re(_ pattern: String) -> NSRegularExpression {
            // swiftlint:disable:next force_try
            try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        }
        return [
            (re(#"^\s*[A-Za-z0-9_.\-]+(?=\s*=)"#), .systemBlue), // keys
            (re(#"\b-?\d+(\.\d+)?\b"#), .systemOrange), // numbers
            (re(#"\b(true|false)\b"#), .systemPurple), // booleans
            (re(#"^\s*\[\[?[^\]]*\]\]?"#), .systemPink), // table headers
            (re(#""(?:\\.|[^"\\])*"|'[^']*'"#), .systemRed), // strings
            (re(#"#[^\n]*"#), .systemGreen), // comments (last)
        ]
    }()

    static func apply(to storage: NSTextStorage, font: NSFont) {
        let full = NSRange(location: 0, length: storage.length)
        storage.setAttributes([.font: font, .foregroundColor: NSColor.labelColor], range: full)
        let text = storage.string
        let range = NSRange(text.startIndex..., in: text)
        for rule in rules {
            rule.regex.enumerateMatches(in: text, range: range) { match, _, _ in
                if let match {
                    storage.addAttribute(.foregroundColor, value: rule.color, range: match.range)
                }
            }
        }
    }
}
