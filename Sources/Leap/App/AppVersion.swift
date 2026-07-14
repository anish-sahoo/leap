import Foundation

/// App version string from the bundle's Info.plist (set by Scripts/bundle.sh
/// from the git tag). Falls back to "dev" when running the bare SPM binary.
var appVersion: String {
    let info = Bundle.main.infoDictionary
    guard let short = info?["CFBundleShortVersionString"] as? String else { return "dev" }
    if let build = info?["CFBundleVersion"] as? String, build != short {
        return "\(short) (\(build))"
    }
    return short
}
