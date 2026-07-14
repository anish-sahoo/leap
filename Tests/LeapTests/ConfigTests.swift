import Testing
@testable import Leap

@Suite("Config TOML")
struct ConfigTests {
    @Test("starter config round-trips through TOML")
    func roundTrip() throws {
        let original = Config.starter
        let text = try ConfigStore.encodeForTests(original)
        let decoded = try ConfigStore.validate(text)

        #expect(decoded.version == original.version)
        #expect(decoded.slots.count == original.slots.count)
        #expect(decoded.slots.first?.hotkey == "alt+1")
        #expect(decoded.slots.first?.action.type == "app")
    }

    @Test("valid TOML with a script action decodes")
    func scriptAction() throws {
        let toml = """
        version = 1

        [[slots]]
        id = "btop"
        hotkey = "alt+6"
        label = "btop"

        [slots.action]
        type = "script"
        interpreter = "bash"
        body = "echo hi"
        """
        let config = try ConfigStore.validate(toml)
        let action = try #require(config.slots.first?.action)
        #expect(action.type == "script")
        #expect(action.interpreter == "bash")
        #expect(action.body == "echo hi")
    }

    @Test("malformed TOML is rejected")
    func rejectsMalformed() {
        #expect(throws: (any Error).self) {
            _ = try ConfigStore.validate("this is not = = valid toml [[[")
        }
    }

    @Test("missing required field is rejected")
    func rejectsMissingField() {
        // `hotkey` omitted -> decoding must fail.
        let toml = """
        version = 1

        [[slots]]
        id = "x"
        label = "X"

        [slots.action]
        type = "app"
        target = "/Applications/Foo.app"
        """
        #expect(throws: (any Error).self) {
            _ = try ConfigStore.validate(toml)
        }
    }
}
