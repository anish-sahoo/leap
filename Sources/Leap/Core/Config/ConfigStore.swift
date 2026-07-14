import Foundation
import TOMLKit

/// Loads/saves the TOML bindings document at ~/.config/leap/config.toml.
/// The file is human-editable (comments allowed) and is the single source of
/// truth shared by the GUI, the (future) CLI, and hand edits.
enum ConfigStore {
    struct ValidationError: LocalizedError {
        let message: String
        var errorDescription: String? {
            message
        }
    }

    static var directory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/leap", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("config.toml")
    }

    // MARK: - Load / save (typed)

    static func load() -> Config {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let seeded = Config.starter
            try? save(seeded)
            Log.config.info("wrote starter config to \(fileURL.path)")
            return seeded
        }
        do {
            let config = try decode(rawText())
            Log.config.info("loaded \(config.slots.count) slots from \(fileURL.path)")
            return config
        } catch {
            Log.config.error("failed to load (\(error)); falling back to starter")
            return .starter
        }
    }

    static func save(_ config: Config) throws {
        try writeRaw(encode(config))
    }

    // MARK: - Raw text (for the in-UI editor)

    /// The file's current text, or a serialized starter config if none exists.
    static func rawText() -> String {
        (try? String(contentsOf: fileURL, encoding: .utf8)) ?? (try? encode(.starter)) ?? ""
    }

    /// Validate + atomically write raw TOML. Throws ValidationError on bad TOML
    /// so the editor can surface the message without corrupting the file.
    static func writeRaw(_ text: String) throws {
        _ = try validate(text) // parse first; never persist invalid config
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try text.data(using: .utf8)?.write(to: fileURL, options: .atomic)
    }

    // MARK: - Import / export (config sharing)

    /// Copy the current config to an arbitrary location (Save panel target).
    static func export(to url: URL) throws {
        try writeRaw(rawText()) // normalize/validate before sharing
        try FileManager.default.removeItemIfExists(at: url)
        try FileManager.default.copyItem(at: fileURL, to: url)
        Log.config.info("exported config to \(url.path)")
    }

    /// Validate an incoming file, back up the existing config, then install it.
    static func `import`(from url: URL) throws {
        let incoming = try String(contentsOf: url, encoding: .utf8)
        _ = try validate(incoming) // reject bad configs before touching ours
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let backup = directory.appendingPathComponent("config.backup.toml")
            try FileManager.default.removeItemIfExists(at: backup)
            try FileManager.default.copyItem(at: fileURL, to: backup)
            Log.config.info("backed up existing config to \(backup.path)")
        }
        try writeRaw(incoming)
        Log.config.info("imported config from \(url.path)")
    }

    // MARK: - Codec

    static func validate(_ text: String) throws -> Config {
        try decode(text)
    }

    private static func decode(_ text: String) throws -> Config {
        do {
            return try TOMLDecoder().decode(Config.self, from: text)
        } catch {
            throw ValidationError(message: String(describing: error))
        }
    }

    private static func encode(_ config: Config) throws -> String {
        try TOMLEncoder().encode(config)
    }

    #if DEBUG
        /// Test hook: serialize a Config to TOML (encode is otherwise private).
        static func encodeForTests(_ config: Config) throws -> String {
            try encode(config)
        }
    #endif
}

private extension FileManager {
    func removeItemIfExists(at url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
    }
}
