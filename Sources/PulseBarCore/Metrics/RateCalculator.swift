import Foundation

/// Pure byte-counter → bytes/second helper used by `NetworkSampler`.
///
/// Handles first sample, counter reset/wrap, and sleep-sized gaps without
/// inventing rates. Stateful callers must keep one calculator per counter
/// stream and only touch it from a single serial context.
public struct RateCalculator: Sendable, Equatable {
    public struct Sample: Sendable, Equatable {
        public var bytes: UInt64
        public var date: Date

        public init(bytes: UInt64, date: Date) {
            self.bytes = bytes
            self.date = date
        }
    }

    private var previous: Sample?

    /// Maximum elapsed seconds accepted for a rate. Larger gaps (sleep/wake)
    /// reset the baseline and return `nil` instead of a spike.
    public var maxElapsed: TimeInterval

    public init(maxElapsed: TimeInterval = 10) {
        self.maxElapsed = maxElapsed
    }

    public var hasBaseline: Bool {
        previous != nil
    }

    public mutating func reset() {
        previous = nil
    }

    /// Records `bytes` at `date` and returns B/s since the previous sample, or
    /// `nil` when a rate cannot be computed honestly.
    public mutating func rate(bytes: UInt64, at date: Date) -> Double? {
        defer { previous = Sample(bytes: bytes, date: date) }

        guard let previous else { return nil }

        let elapsed = date.timeIntervalSince(previous.date)
        guard elapsed > 0, elapsed < maxElapsed else { return nil }
        guard bytes >= previous.bytes else { return nil }

        return Double(bytes - previous.bytes) / elapsed
    }
}
