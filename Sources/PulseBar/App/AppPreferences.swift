import Combine
import Foundation
import ServiceManagement

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case icon
    case cpu
    case memory
    case lowestBattery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .icon: return "仅图标"
        case .cpu: return "CPU 使用率"
        case .memory: return "内存使用率"
        case .lowestBattery: return "最低外设电量"
        }
    }
}

@MainActor
final class AppPreferences: ObservableObject {
    private enum Key {
        static let menuBarMode = "pulsebar.menuBarMode"
        static let refreshInterval = "pulsebar.refreshInterval"
        static let batteryPollingEnabled = "pulsebar.batteryPollingEnabled"
        static let batteryInterval = "pulsebar.batteryInterval"
    }

    private let defaults: UserDefaults

    @Published var menuBarMode: MenuBarDisplayMode {
        didSet { defaults.set(menuBarMode.rawValue, forKey: Key.menuBarMode) }
    }

    @Published var refreshInterval: TimeInterval {
        didSet { defaults.set(refreshInterval, forKey: Key.refreshInterval) }
    }

    @Published var batteryPollingEnabled: Bool {
        didSet { defaults.set(batteryPollingEnabled, forKey: Key.batteryPollingEnabled) }
    }

    @Published var batteryInterval: TimeInterval {
        didSet { defaults.set(batteryInterval, forKey: Key.batteryInterval) }
    }

    @Published private(set) var loginItemStatus: SMAppService.Status
    @Published var loginItemError: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedMode = defaults
            .string(forKey: Key.menuBarMode)
            .flatMap(MenuBarDisplayMode.init(rawValue:)) ?? .cpu
        self.menuBarMode = savedMode
        self.refreshInterval = defaults.object(forKey: Key.refreshInterval) as? Double ?? 1
        self.batteryPollingEnabled = defaults.object(forKey: Key.batteryPollingEnabled) as? Bool ?? true
        self.batteryInterval = defaults.object(forKey: Key.batteryInterval) as? Double ?? 30
        self.loginItemStatus = SMAppService.mainApp.status
    }

    var isLaunchAtLoginEnabled: Bool {
        loginItemStatus == .enabled || loginItemStatus == .requiresApproval
    }

    var launchAtLoginDescription: String {
        switch loginItemStatus {
        case .enabled:
            return "已开启，登录 Mac 后自动启动。"
        case .requiresApproval:
            return "等待系统授权，请在登录项中允许 PulseBar。"
        case .notRegistered:
            return "未开启。关闭时需手动启动。"
        case .notFound:
            return "请先将 PulseBar 放入“应用程序”文件夹。"
        @unknown default:
            return "请在系统设置的登录项中检查。"
        }
    }

    func refreshLoginItemStatus() {
        loginItemStatus = SMAppService.mainApp.status
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
        refreshLoginItemStatus()
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
