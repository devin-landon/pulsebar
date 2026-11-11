import Foundation

/// Pure CPU tick math shared by `CPUSampler`.
///
/// Tick arrays are flattened as `[user, system, idle, nice]` per core.
/// Deltas use wrapping subtraction so 32-bit counters can roll over safely.
public enum CPUTickAccumulator {
    public static let statesPerCore = 4

    /// Wrapping unsigned delta (`current &- previous`).
    public static func delta(current: UInt32, previous: UInt32) -> UInt32 {
        current &- previous
    }

    /// Aggregated utilization in `0...1`, or `nil` when inputs are unusable.
    public static func utilization(previous: [UInt32], current: [UInt32]) -> Double? {
        guard previous.count == current.count,
              !current.isEmpty,
              current.count % statesPerCore == 0 else {
            return nil
        }

        var busy: Double = 0
        var total: Double = 0

        for index in stride(from: 0, to: current.count, by: statesPerCore) {
            let user = Double(delta(current: current[index], previous: previous[index]))
            let system = Double(delta(current: current[index + 1], previous: previous[index + 1]))
            let idle = Double(delta(current: current[index + 2], previous: previous[index + 2]))
            let nice = Double(delta(current: current[index + 3], previous: previous[index + 3]))

            busy += user + system + nice
            total += user + system + idle + nice
        }

        guard total > 0 else { return nil }
        return min(max(busy / total, 0), 1)
    }
}
