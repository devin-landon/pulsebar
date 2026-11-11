import Foundation

enum AppEnvironment {
    static let version = "0.1.0"
    static let build = "1"

    /// `PULSEBAR_DEMO=1 swift run PulseBar` shows fake devices for UI work.
    static var isDemo: Bool {
        ProcessInfo.processInfo.environment["PULSEBAR_DEMO"] == "1"
    }
}
