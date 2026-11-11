import AppKit
import PulseBarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()

    private var preferences: AppPreferences!
    private var store: DashboardStore!
    private var statusController: StatusItemController!
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        preferences = AppPreferences()

        let battery: PeripheralBatteryMonitor
        if AppEnvironment.isDemo {
            battery = PeripheralBatteryMonitor(
                providers: [DemoBatteryProvider()],
                interval: preferences.batteryInterval
            )
        } else {
            battery = PeripheralBatteryMonitor(
                providers: [HIDBatteryProvider(), GameControllerBatteryProvider()],
                interval: preferences.batteryInterval
            )
        }

        if !preferences.batteryPollingEnabled {
            battery.setEnabled(false)
        }

        let metrics: SystemMetricsProviding = AppEnvironment.isDemo
            ? DemoMetricsProvider()
            : SystemMetricsProvider()

        store = DashboardStore(
            metrics: metrics,
            battery: battery,
            interval: preferences.refreshInterval
        )

        let actions = StatusItemController.Actions(
            openSettings: { [weak self] in self?.openSettings() },
            openAbout: { [weak self] in self?.openAbout() },
            quit: { NSApp.terminate(nil) }
        )

        statusController = StatusItemController(
            store: store,
            preferences: preferences,
            actions: actions
        )

        store.start()
        statusController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Windows

    func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                preferences: preferences,
                battery: store.battery,
                store: store
            )
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    func openAbout() {
        NSApp.activate(ignoringOtherApps: true)

        let credits = NSAttributedString(
            string: "系统监控与外设电量\n设计灵感来自 einsy1/pulse · MIT License",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )

        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "PulseBar",
            .applicationVersion: AppEnvironment.version,
            .version: AppEnvironment.build,
            .credits: credits,
        ])
    }
}
