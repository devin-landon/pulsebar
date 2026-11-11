import AppKit
import PulseBarCore
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    struct Actions {
        let openSettings: () -> Void
        let openAbout: () -> Void
        let quit: () -> Void
    }

    private let statusItem: NSStatusItem
    private let store: DashboardStore
    private let preferences: AppPreferences
    private let actions: Actions

    private var popover: NSPopover?
    private var labelTimer: Timer?

    init(store: DashboardStore, preferences: AppPreferences, actions: Actions) {
        self.store = store
        self.preferences = preferences
        self.actions = actions
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureButton()
        updateLabel()
    }

    deinit {
        labelTimer?.invalidate()
    }

    func start() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateLabel()
            }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        labelTimer = timer
    }

    // MARK: - Button

    private func configureButton() {
        guard let button = statusItem.button else { return }

        button.image = NSImage(
            systemSymbolName: "waveform.path.ecg",
            accessibilityDescription: "PulseBar"
        )
        button.image?.isTemplate = true
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        button.target = self
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "PulseBar · 系统监控与外设电量"
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func updateLabel() {
        guard let button = statusItem.button else { return }

        let symbol: String
        switch preferences.menuBarMode {
        case .icon:
            button.title = ""
            symbol = "waveform.path.ecg"

        case .cpu:
            let text = MetricFormatter.percentInt(store.snapshot.cpuUsage).map { "\($0)%" } ?? "—"
            button.title = " " + text
            symbol = "waveform.path.ecg"

        case .memory:
            let text = MetricFormatter.percentInt(store.snapshot.memoryUsage).map { "\($0)%" } ?? "—"
            button.title = " " + text
            symbol = "waveform.path.ecg"

        case .lowestBattery:
            let lowest = store.battery.devices.compactMap(\.level).min()
            let text = lowest.map { "\(Int(($0 * 100).rounded()))%" } ?? "—"
            button.title = " " + text
            symbol = Self.batterySymbol(for: lowest)
        }

        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "PulseBar")
        button.image?.isTemplate = true
    }

    private static func batterySymbol(for level: Double?) -> String {
        guard let level else { return "battery.0" }
        switch level {
        case ..<0.13: return "battery.0"
        case ..<0.38: return "battery.25"
        case ..<0.63: return "battery.50"
        case ..<0.88: return "battery.75"
        default: return "battery.100"
        }
    }

    // MARK: - Popover

    private func togglePopover() {
        if popover?.isShown == true {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }

        store.sample()
        store.battery.refresh()

        let popover = makePopoverIfNeeded()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func closePopover() {
        popover?.performClose(nil)
    }

    private func makePopoverIfNeeded() -> NSPopover {
        if let popover { return popover }

        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(
            width: Theme.Metric.panelWidth,
            height: Theme.Metric.panelHeight
        )
        popover.contentViewController = NSHostingController(
            rootView: DashboardView(
                store: store,
                onOpenSettings: actions.openSettings,
                onOpenAbout: actions.openAbout,
                onQuit: actions.quit,
                onCollapse: { [weak self] in
                    self?.closePopover()
                }
            )
        )
        self.popover = popover
        return popover
    }

    // MARK: - Context menu

    private func showContextMenu() {
        closePopover()

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "打开面板",
            action: #selector(openPanelFromMenu),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "设置…",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "关于 PulseBar",
            action: #selector(openAboutFromMenu),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "退出 PulseBar",
            action: #selector(quitFromMenu),
            keyEquivalent: "q"
        ))
        menu.items.forEach { $0.target = self }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openPanelFromMenu() {
        showPopover()
    }

    @objc private func openSettingsFromMenu() {
        actions.openSettings()
    }

    @objc private func openAboutFromMenu() {
        actions.openAbout()
    }

    @objc private func quitFromMenu() {
        actions.quit()
    }
}
