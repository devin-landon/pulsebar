import Foundation

/// Deterministic provider used by `--snapshot` renders and UI demo mode.
public final class DemoMetricsProvider: SystemMetricsProviding {
    private var tick: Double = 0

    public init() {}

    public func sample() -> SystemSnapshot {
        tick += 1
        let wave = sin(tick / 4) * 0.035
        let memoryTotal: UInt64 = 24 * 1024 * 1024 * 1024

        return SystemSnapshot(
            cpuUsage: min(max(0.26 + wave, 0), 1),
            memoryUsage: 0.77,
            memoryUsedBytes: 18_500_000_000,
            memoryTotalBytes: memoryTotal,
            gpuUsage: 0.24,
            cpuTemperatureCelsius: 64,
            diskUsedBytes: 189_400_000_000,
            diskTotalBytes: 245_000_000_000,
            downloadBytesPerSecond: 7_200,
            uploadBytesPerSecond: 4_100,
            sampledAt: Date()
        )
    }
}
