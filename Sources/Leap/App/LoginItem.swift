import ServiceManagement

/// Launch-at-login via the modern ServiceManagement API (macOS 13+).
///
/// IMPORTANT: SMAppService.mainApp only works when the app runs from a proper
/// `.app` bundle (see Scripts/bundle.sh). Running the bare SPM binary will make
/// register() throw — that's expected; use the bundled app for this feature.
@MainActor
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            Log.login.info("start-at-login \(enabled ? "enabled" : "disabled")")
        } catch {
            Log.login
                .error(
                    "failed to \(enabled ? "enable" : "disable"): \(error) (are you running the bundled .app?)"
                )
        }
    }
}
