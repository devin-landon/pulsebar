import Combine
import Foundation

/// Polls all battery providers and publishes a merged device list.
///
/// Battery polling is intentionally slower than metrics polling (default 30 s).
/// It is paused when disabled in Settings and can be refreshed manually.
@MainActor
public final class PeripheralBatteryMonitor: ObservableObject {
    @Published public private(set) var devices: [PeripheralBattery] = []
    @Published public private(set) var lastUpdated: Date?
    @Published public private(set) var isEnabled: Bool = true

    public private(set) var interval: TimeInterval

    private let providers: [any BatteryProviding]
    private var timer: Timer?

    public init(providers: [any BatteryProviding], interval: TimeInterval = 30) {
        self.providers = providers
        self.interval = max(5, interval)
    }

    deinit {
        timer?.invalidate()
    }

    public var hasLowBattery: Bool {
        devices.contains { $0.isLow }
    }

    public func start() {
        guard isEnabled else { return }
        refresh()
        schedule()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    public func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled

        if enabled {
            start()
        } else {
            stop()
            devices = []
            lastUpdated = nil
        }
    }

    public func setInterval(_ newInterval: TimeInterval) {
        let clamped = max(5, newInterval)
        guard clamped != interval else { return }
        interval = clamped

        if isEnabled, timer != nil {
            schedule()
        }
    }

    public func refresh() {
        let batches = providers.map { $0.read() }
        devices = BatteryMerger.merge(batches)
        lastUpdated = Date()
    }

    private func schedule() {
        timer?.invalidate()

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        timer.tolerance = min(5, max(1, interval * 0.1))
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
