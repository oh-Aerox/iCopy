import AppKit

/// Keep the delegate alive for the whole process; NSApplication does not retain it strongly.
enum AppRuntime {
    /// Process-lifetime singleton, only touched from AppKit’s main thread.
    nonisolated(unsafe) static let delegate = AppDelegate()
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = AppRuntime.delegate
app.run()

