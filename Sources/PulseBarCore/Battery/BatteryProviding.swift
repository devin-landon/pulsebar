import Foundation

/// A battery data source. Providers are deliberately small and independent so
/// private or fallback APIs can be added without touching the UI.
public protocol BatteryProviding {
    var source: BatterySource { get }
    func read() -> [PeripheralBattery]
}
