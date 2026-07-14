import Carbon.HIToolbox
import Testing
@testable import Leap

@Suite("Hotkey parsing")
struct HotkeyTests {
    @Test("parses a single modifier + digit")
    func singleModifier() throws {
        let hotkey = try #require(Hotkey.parse("alt+1"))
        #expect(hotkey.keyCode == UInt32(kVK_ANSI_1))
        #expect(hotkey.modifiers == UInt32(optionKey))
    }

    @Test("combines multiple modifiers")
    func multipleModifiers() throws {
        let hotkey = try #require(Hotkey.parse("cmd+shift+3"))
        #expect(hotkey.keyCode == UInt32(kVK_ANSI_3))
        #expect(hotkey.modifiers == UInt32(cmdKey) | UInt32(shiftKey))
    }

    @Test("is case-insensitive and ignores whitespace")
    func caseAndWhitespace() throws {
        let a = try #require(Hotkey.parse("ALT + 2"))
        let b = try #require(Hotkey.parse("alt+2"))
        #expect(a.keyCode == b.keyCode)
        #expect(a.modifiers == b.modifiers)
    }

    @Test("accepts modifier aliases", arguments: ["alt+1", "opt+1", "option+1"])
    func aliases(combo: String) throws {
        let hotkey = try #require(Hotkey.parse(combo))
        #expect(hotkey.modifiers == UInt32(optionKey))
    }

    @Test("rejects malformed input", arguments: ["", "alt+", "cmd+shift", "alt+z"])
    func rejectsGarbage(combo: String) {
        #expect(Hotkey.parse(combo) == nil)
    }
}
