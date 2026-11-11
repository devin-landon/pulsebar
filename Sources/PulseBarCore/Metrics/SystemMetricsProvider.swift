import Foundation

public protocol SystemMetricsProviding: AnyObject {
    func sample() -> SystemSnapshot
    /// Clears stateful sampler baselines (CPU ticks, network counters) after sleep.
    func resetBaselines()
}

public extension SystemMetricsProviding {
    func resetBaselines() {}
}

/// Production provider. Must only be sampled from `MetricsScheduler`'s serial
/// queue so `CPUSampler` / `NetworkSampler` state stays single-threaded.
public final class SystemMetricsProvider: SystemMetricsProviding {
    private let cpu = CPUSampler()
    private let memory = MemorySampler()
    private let disk = DiskSampler()
    private let network = NetworkSampler()
    private let gpu = GPUSampler()
    private let temperature = TemperatureSampler()

    public init() {}

    public func sample() -> SystemSnapshot {
        let cpuUsage = cpu.sample()
        let memoryReading = memory.sample()
        let diskReading = disk.sample()
        let networkReading = network.sample()
        let gpuUsage = gpu.sample()
        let temperatureCelsius = temperature.sample()

        return SystemSnapshot(
            cpuUsage: cpuUsage,
            memoryUsage: memoryReading.usage,
            memoryUsedBytes: memoryReading.used,
            memoryTotalBytes: memoryReading.total,
            gpuUsage: gpuUsage,
            cpuTemperatureCelsius: temperatureCelsius,
            diskUsedBytes: diskReading.used,
            diskTotalBytes: diskReading.total,
            downloadBytesPerSecond: networkReading.download,
            uploadBytesPerSecond: networkReading.upload,
            sampledAt: Date()
        )
    }

    public func resetBaselines() {
        cpu.reset()
        network.reset()
    }
}
