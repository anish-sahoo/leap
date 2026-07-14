import Testing
@testable import Leap

@Suite("Config validation")
struct ConfigValidatorTests {
    private let valid = """
    version = 1

    [[slots]]
    id = "chrome"
    hotkey = "alt+1"
    label = "Chrome"
    [slots.action]
    type = "app"
    target = "/Applications/Google Chrome.app"
    """

    @Test("accepts a valid config")
    func acceptsValid() {
        #expect(ConfigValidator.validate(valid).isEmpty)
    }

    @Test("flags an unknown top-level key")
    func unknownTopKey() {
        let text = valid + "\nnonsense = true\n"
        let errors = ConfigValidator.validate(text)
        #expect(errors.contains { $0.contains("unknown key 'nonsense'") })
    }

    @Test("flags an unknown key inside a slot's action")
    func unknownActionKey() {
        let text = valid + "\nbogus = 3\n"
        #expect(ConfigValidator.validate(text).contains { $0.contains("unknown key 'bogus'") })
    }

    @Test("rejects an invalid hotkey")
    func invalidHotkey() {
        let text = valid.replacingOccurrences(of: "alt+1", with: "alt+")
        #expect(ConfigValidator.validate(text).contains { $0.contains("invalid hotkey") })
    }

    @Test("rejects a duplicate hotkey")
    func duplicateHotkey() {
        let text = """
        version = 1
        [[slots]]
        id = "a"
        hotkey = "alt+1"
        [slots.action]
        type = "command"
        target = "echo a"
        [[slots]]
        id = "b"
        hotkey = "alt+1"
        [slots.action]
        type = "command"
        target = "echo b"
        """
        #expect(ConfigValidator.validate(text).contains { $0.contains("duplicate hotkey") })
    }

    @Test("rejects an unknown action type")
    func badActionType() {
        let text = valid.replacingOccurrences(of: "type = \"app\"", with: "type = \"teleport\"")
        #expect(ConfigValidator.validate(text).contains { $0.contains("unknown action type") })
    }

    @Test("rejects an invalid cheatsheet position")
    func badCheatsheetPosition() {
        let text = valid + "\n[cheatsheet]\nposition = \"nowhere\"\n"
        #expect(ConfigValidator.validate(text).contains { $0.contains("cheatsheet.position") })
    }

    @Test("rejects an invalid terminal")
    func badTerminal() {
        let text = valid.replacingOccurrences(of: "version = 1", with: "version = 1\nterminal = \"hyper\"")
        #expect(ConfigValidator.validate(text).contains { $0.contains("terminal 'hyper'") })
    }

    @Test("accepts a valid terminal")
    func goodTerminal() {
        let text = valid.replacingOccurrences(
            of: "version = 1",
            with: "version = 1\nterminal = \"ghostty\""
        )
        #expect(ConfigValidator.validate(text).isEmpty)
    }

    @Test("reports a syntax error")
    func syntaxError() {
        #expect(ConfigValidator.validate("this is not toml [[[").contains { $0.contains("Syntax error") })
    }
}
