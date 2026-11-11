import Foundation
import GameController

/// Public GameController API. Works for Xbox / DualSense / DualShock and other
/// MFi controllers without entitlements or private frameworks.
public struct GameControllerBatteryProvider: BatteryProviding {
    public let source: BatterySource = .gameController

    public init() {}

    public func read() -> [PeripheralBattery] {
        GCController.controllers().enumerated().compactMap { index, controller in
            guard let battery = controller.battery else { return nil }

            let rawName = controller.vendorName ?? controller.productCategory
            let name = rawName.isEmpty ? "游戏手柄" : rawName
            let level: Double? = battery.batteryLevel >= 0 ? Double(battery.batteryLevel) : nil

            let state: BatteryState
            switch battery.batteryState {
            case .charging: state = .charging
            case .discharging: state = .discharging
            case .full: state = .full
            default: state = .unknown
            }

            return PeripheralBattery(
                id: "gc:\(name.lowercased()):\(index)",
                name: name,
                kind: .gamepad,
                level: level,
                state: state,
                source: .gameController,
                isConnected: true,
                lastUpdated: Date()
            )
        }
    }
}
