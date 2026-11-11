import Foundation
import PulseBarCore

/// Static devices used by demo mode and the README snapshot.
struct DemoBatteryProvider: BatteryProviding {
    let source: BatterySource = .hid

    func read() -> [PeripheralBattery] {
        let now = Date()
        return [
            PeripheralBattery(
                id: "demo:magic-mouse",
                name: "Magic Mouse",
                kind: .mouse,
                level: 0.78,
                state: .discharging,
                source: .hid,
                isConnected: true,
                lastUpdated: now
            ),
            PeripheralBattery(
                id: "demo:magic-keyboard",
                name: "Magic Keyboard",
                kind: .keyboard,
                level: 0.42,
                state: .discharging,
                source: .hid,
                isConnected: true,
                lastUpdated: now
            ),
            PeripheralBattery(
                id: "demo:airpods",
                name: "AirPods Pro",
                kind: .headphones,
                level: 0.16,
                state: .charging,
                source: .bluetoothAudio,
                isConnected: true,
                lastUpdated: now
            ),
        ]
    }
}
