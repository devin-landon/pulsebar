import Foundation

/// Presentation helpers shared by the menu bar label, dashboard and tests.
public enum MetricFormatter {
    private static let byteUnits = ["B", "KB", "MB", "GB", "TB"]

    /// 0...1 ratio to a whole percentage, e.g. `0.264` -> `"26"`.
    public static func percent(_ value: Double?, decimals: Int = 0) -> String {
        guard let value, value.isFinite else { return "—" }
        let clamped = min(max(value, 0), 1)
        return String(format: "%.\(max(0, decimals))f", clamped * 100)
    }

    public static func percentInt(_ value: Double?) -> Int? {
        guard let value, value.isFinite else { return nil }
        return Int((min(max(value, 0), 1) * 100).rounded())
    }

    public static func number(_ value: Double?, decimals: Int = 0) -> String {
        guard let value, value.isFinite else { return "—" }
        return String(format: "%.\(max(0, decimals))f", value)
    }

    public static func byteCount(_ bytes: UInt64?) -> String {
        guard let bytes else { return "—" }
        return humanReadable(Double(bytes), perSecond: false)
    }

    public static func rate(_ bytesPerSecond: Double?) -> String {
        guard let bytesPerSecond, bytesPerSecond.isFinite, bytesPerSecond >= 0 else { return "—" }
        return humanReadable(bytesPerSecond, perSecond: true)
    }

    public static func temperature(_ celsius: Double?) -> String {
        guard let celsius, celsius.isFinite else { return "—" }
        return String(format: "%.0f", celsius)
    }

    public static func battery(_ level: Double?) -> String {
        guard let level, level.isFinite else { return "—" }
        return "\(Int((min(max(level, 0), 1) * 100).rounded()))%"
    }

    private static func humanReadable(_ value: Double, perSecond: Bool) -> String {
        var amount = max(value, 0)
        var index = 0
        // Decimal units match Finder / Activity Monitor storage reporting.
        while amount >= 1000, index < byteUnits.count - 1 {
            amount /= 1000
            index += 1
        }

        let suffix = perSecond ? "/s" : ""
        if index == 0 {
            return "\(Int(amount.rounded())) \(byteUnits[index])\(suffix)"
        }

        // Rates read better as whole numbers once they are above 1 KB/s.
        let decimals = perSecond && amount >= 10 ? 0 : 1
        return String(format: "%.\(decimals)f %@%@", amount, byteUnits[index], suffix)
    }
}
