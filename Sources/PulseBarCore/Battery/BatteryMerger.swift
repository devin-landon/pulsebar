import Foundation

/// Combines the output of several providers, de-duplicates by identifier and
/// produces a stable display order.
public enum BatteryMerger {
    public static func merge(_ batches: [[PeripheralBattery]]) -> [PeripheralBattery] {
        var byIdentifier: [String: PeripheralBattery] = [:]

        for batch in batches {
            for device in batch {
                if let current = byIdentifier[device.id] {
                    byIdentifier[device.id] = preferred(current, device)
                } else {
                    byIdentifier[device.id] = device
                }
            }
        }

        return byIdentifier.values.sorted { lhs, rhs in
            if lhs.kind.sortOrder != rhs.kind.sortOrder {
                return lhs.kind.sortOrder < rhs.kind.sortOrder
            }
            if lhs.isLow != rhs.isLow {
                return lhs.isLow
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    private static func preferred(
        _ lhs: PeripheralBattery,
        _ rhs: PeripheralBattery
    ) -> PeripheralBattery {
        var winner = lhs.lastUpdated >= rhs.lastUpdated ? lhs : rhs

        if winner.level == nil {
            winner.level = lhs.level ?? rhs.level
        }
        if winner.state == .unknown {
            winner.state = lhs.state != .unknown ? lhs.state : rhs.state
        }
        if winner.name.isEmpty {
            winner.name = lhs.name.isEmpty ? rhs.name : lhs.name
        }
        return winner
    }
}
