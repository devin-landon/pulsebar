import Foundation
import IOKit

/// Reads Apple HID peripherals (Magic Mouse / Keyboard / Trackpad and some
/// third-party devices) from the IORegistry.
///
/// This is a public IOKit read and requires no special entitlement. Devices
/// that do not publish `BatteryPercent` are skipped rather than guessed.
public struct HIDBatteryProvider: BatteryProviding {
    public let source: BatterySource = .hid

    public init() {}

    public func read() -> [PeripheralBattery] {
        guard let matching = IOServiceMatching("AppleDeviceManagementHIDEventService") else {
            return []
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var devices: [PeripheralBattery] = []
        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            defer { IOObjectRelease(service) }

            var propertiesRef: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(
                service,
                &propertiesRef,
                kCFAllocatorDefault,
                0
            ) == KERN_SUCCESS,
                let properties = propertiesRef?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            if let device = Self.decode(properties: properties) {
                devices.append(device)
            }
        }
        return devices
    }

    // MARK: - Pure decoding (unit tested)

    static func decode(properties: [String: Any], now: Date = Date()) -> PeripheralBattery? {
        guard let percent = properties["BatteryPercent"] as? NSNumber else { return nil }

        let name = (properties["Product"] as? String)
            ?? (properties["ProductName"] as? String)
            ?? "未命名外设"

        // The built-in keyboard/trackpad expose a HID service without a battery.
        if name.localizedCaseInsensitiveContains("Internal") {
            return nil
        }

        let usagePage = (properties["PrimaryUsagePage"] as? NSNumber)?.intValue ?? 0
        let usage = (properties["PrimaryUsage"] as? NSNumber)?.intValue ?? 0
        let serial = (properties["SerialNumber"] as? NSString) as String?
        let identifier = serial.flatMap { $0.isEmpty ? nil : "hid:\($0)" }
            ?? "hid:\(name.lowercased())"

        return PeripheralBattery(
            id: identifier,
            name: name,
            kind: kind(for: name, usagePage: usagePage, usage: usage),
            level: percent.doubleValue / 100,
            state: state(from: properties["BatteryStatus"]),
            source: .hid,
            isConnected: true,
            lastUpdated: now
        )
    }

    static func kind(for name: String, usagePage: Int, usage: Int) -> PeripheralKind {
        if usagePage == 0x01 {
            switch usage {
            case 0x02: return .mouse
            case 0x06: return .keyboard
            case 0x0D: return .trackpad
            default: break
            }
        }

        let lowercased = name.lowercased()
        if lowercased.contains("trackpad") { return .trackpad }
        if lowercased.contains("mouse") { return .mouse }
        if lowercased.contains("keyboard") { return .keyboard }
        if lowercased.contains("airpod")
            || lowercased.contains("buds")
            || lowercased.contains("headphone")
            || lowercased.contains("beats") {
            return .headphones
        }
        if lowercased.contains("controller")
            || lowercased.contains("gamepad")
            || lowercased.contains("dualsense")
            || lowercased.contains("dualshock")
            || lowercased.contains("xbox") {
            return .gamepad
        }
        if lowercased.contains("iphone") { return .phone }
        if lowercased.contains("ipad") { return .tablet }
        return .other
    }

    static func state(from value: Any?) -> BatteryState {
        if let string = value as? String {
            switch string.lowercased() {
            case "charging": return .charging
            case "discharging": return .discharging
            case "full", "charged": return .full
            default: return .unknown
            }
        }

        if let number = value as? NSNumber {
            // HID Usage Tables: 1 charging, 2 discharging, 3 full.
            switch number.intValue {
            case 1: return .charging
            case 2: return .discharging
            case 3: return .full
            default: return .unknown
            }
        }

        return .unknown
    }
}
