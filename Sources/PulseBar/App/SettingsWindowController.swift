import AppKit
import PulseBarCore
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    convenience init(
        preferences: AppPreferences,
        battery: PeripheralBatteryMonitor,
        store: DashboardStore
    ) {
        let rootView = SettingsView(
            preferences: preferences,
            battery: battery,
            store: store
        )

        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "PulseBar 设置"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 460, height: 580))
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(red: 0.07, green: 0.075, blue: 0.09, alpha: 1)
        window.setFrameAutosaveName("PulseBarSettings")
        window.center()

        self.init(window: window)
    }
}
