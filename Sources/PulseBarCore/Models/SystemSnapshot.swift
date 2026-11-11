import Foundation

/// A single point-in-time reading of the host machine.
///
/// Every value is optional on purpose: macOS does not expose the same sensors
/// on every Mac. A missing value means "unavailable", never zero.
public struct SystemSnapshot: Sendable, Equatable {
    public var cpuUsage: Double?
    public var memoryUsage: Double?
    public var memoryUsedBytes: UInt64?
    public var memoryTotalBytes: UInt64?
    public var gpuUsage: Double?
    public var cpuTemperatureCelsius: Double?
    public var diskUsedBytes: UInt64?
    public var diskTotalBytes: UInt64?
    public var downloadBytesPerSecond: Double?
    public var uploadBytesPerSecond: Double?
    public var sampledAt: Date

    public init(
        cpuUsage: Double? = nil,
        memoryUsage: Double? = nil,
        memoryUsedBytes: UInt64? = nil,
        memoryTotalBytes: UInt64? = nil,
        gpuUsage: Double? = nil,
        cpuTemperatureCelsius: Double? = nil,
        diskUsedBytes: UInt64? = nil,
        diskTotalBytes: UInt64? = nil,
        downloadBytesPerSecond: Double? = nil,
        uploadBytesPerSecond: Double? = nil,
        sampledAt: Date = Date()
    ) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.gpuUsage = gpuUsage
        self.cpuTemperatureCelsius = cpuTemperatureCelsius
        self.diskUsedBytes = diskUsedBytes
        self.diskTotalBytes = diskTotalBytes
        self.downloadBytesPerSecond = downloadBytesPerSecond
        self.uploadBytesPerSecond = uploadBytesPerSecond
        self.sampledAt = sampledAt
    }

    /// Placeholder used before the first sample (or when a provider fails).
    public static let empty = SystemSnapshot(sampledAt: .distantPast)

    public var diskUsage: Double? {
        guard let used = diskUsedBytes, let total = diskTotalBytes, total > 0 else { return nil }
        return min(max(Double(used) / Double(total), 0), 1)
    }

    public var isInitial: Bool {
        sampledAt == .distantPast
    }
}
