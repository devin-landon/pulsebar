import Combine
import Foundation
import PulseBarCore

@MainActor
final class DashboardStore: ObservableObject {
    @Published private(set) var snapshot: SystemSnapshot = .empty
    @Published private(set) var history: [SystemSnapshot] = []

    let battery: PeripheralBatteryMonitor
    let deviceName: String

    private let metrics: SystemMetricsProviding
    private var interval: TimeInterval
    private var timer: Timer?

    init(
        metrics: SystemMetricsProviding,
        battery: PeripheralBatteryMonitor,
        interval: TimeInterval = 1
    ) {
        self.metrics = metrics
        self.battery = battery
        self.interval = max(0.5, interval)
        self.deviceName = Self.resolveDeviceName()
    }

    var refreshInterval: TimeInterval { interval }

    func start() {
        sample()
        if battery.isEnabled {
            battery.start()
        }
        schedule()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        battery.stop()
    }

    func sample() {
        let next = metrics.sample()
        snapshot = next
        history.append(next)
        if history.count > 90 {
            history.removeFirst(history.count - 90)
        }
    }

    func setInterval(_ newValue: TimeInterval) {
        let clamped = max(0.5, newValue)
        guard clamped != interval else { return }
        interval = clamped
        if timer != nil {
            schedule()
        }
    }

    private func schedule() {
        timer?.invalidate()

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sample()
            }
        }
        timer.tolerance = min(0.15, interval * 0.1)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private static func resolveDeviceName() -> String {
        if let localizedName = Host.current().localizedName, !localizedName.isEmpty {
            return localizedName
        }
        return ProcessInfo.processInfo.hostName
            .replacingOccurrences(of: ".local", with: "")
    }
}
