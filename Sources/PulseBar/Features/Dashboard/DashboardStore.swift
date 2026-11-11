import Combine
import Foundation
import PulseBarCore

@MainActor
final class DashboardStore: ObservableObject {
    @Published private(set) var snapshot: SystemSnapshot = .empty
    @Published private(set) var history: [SystemSnapshot] = []

    let battery: PeripheralBatteryMonitor
    let deviceName: String

    private let scheduler: MetricsScheduler
    private var interval: TimeInterval

    init(
        metrics: SystemMetricsProviding,
        battery: PeripheralBatteryMonitor,
        interval: TimeInterval = 1
    ) {
        self.battery = battery
        self.interval = max(0.5, interval)
        self.deviceName = Self.resolveDeviceName()
        self.scheduler = MetricsScheduler(provider: metrics, interval: self.interval)
    }

    var refreshInterval: TimeInterval { interval }

    func start() {
        scheduler.start { [weak self] snapshot in
            Task { @MainActor [weak self] in
                self?.apply(snapshot)
            }
        }

        if battery.isEnabled {
            battery.start()
        }
    }

    func stop() {
        scheduler.stop()
        battery.stop()
    }

    /// Request an immediate background sample (panel open). UI updates when ready.
    func sample() {
        scheduler.requestSample()
    }

    func setInterval(_ newValue: TimeInterval) {
        let clamped = max(0.5, newValue)
        guard clamped != interval else { return }
        interval = clamped
        scheduler.setInterval(clamped)
    }

    // MARK: - Apply

    private func apply(_ next: SystemSnapshot) {
        snapshot = next
        history.append(next)
        if history.count > 90 {
            history.removeFirst(history.count - 90)
        }
    }

    private static func resolveDeviceName() -> String {
        if let localizedName = Host.current().localizedName, !localizedName.isEmpty {
            return localizedName
        }
        return ProcessInfo.processInfo.hostName
            .replacingOccurrences(of: ".local", with: "")
    }
}
