/// Platform boundary for app activation. The domain layer depends only on this;
/// `AXWindowController` is the macOS conformer.
@MainActor
protocol WindowSwitching {
    /// Launch → new-window → focus → cycle for the app at the given bundle path.
    func activate(appAtBundlePath path: String)
}
