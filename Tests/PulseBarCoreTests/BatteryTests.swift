import XCTest
@testable import PulseBarCore

final class BatteryTests: XCTestCase {
    func testHIDDecodeReadsApplePeripheral() {
        let properties: [String: Any] = [
            "Product": "Magic Mouse",
            "BatteryPercent": NSNumber(value: 78),
            "BatteryStatus": "discharging",
            "PrimaryUsagePage": NSNumber(value: 1),
            "PrimaryUsage": NSNumber(value: 2),
            "SerialNumber": "ABC123",
        ]

        let device = HIDBatteryProvider.decode(properties: properties)

        XCTAssertEqual(device?.name, "Magic Mouse")
        XCTAssertEqual(device?.kind, .mouse)
        XCTAssertEqual(device?.level ?? 0, 0.78, accuracy: 0.001)
        XCTAssertEqual(device?.state, .discharging)
        XCTAssertEqual(device?.source, .hid)
        XCTAssertEqual(device?.id, "hid:ABC123")
    }

    func testHIDDecodeSkipsDevicesWithoutBattery() {
        let properties: [String: Any] = [
            "Product": "Apple Internal Keyboard / Trackpad",
        ]
        XCTAssertNil(HIDBatteryProvider.decode(properties: properties))
    }

    func testHIDDecodeInfersKeyboardFromUsage() {
        let properties: [String: Any] = [
            "Product": "Bluetooth Keyboard",
            "BatteryPercent": NSNumber(value: 42),
            "PrimaryUsagePage": NSNumber(value: 1),
            "PrimaryUsage": NSNumber(value: 6),
        ]

        let device = HIDBatteryProvider.decode(properties: properties)
        XCTAssertEqual(device?.kind, .keyboard)
        XCTAssertEqual(device?.id, "hid:bluetooth keyboard")
    }

    func testHIDBatteryStateMapping() {
        XCTAssertEqual(HIDBatteryProvider.state(from: "Charging"), .charging)
        XCTAssertEqual(HIDBatteryProvider.state(from: "Discharging"), .discharging)
        XCTAssertEqual(HIDBatteryProvider.state(from: NSNumber(value: 3)), .full)
        XCTAssertEqual(HIDBatteryProvider.state(from: nil), .unknown)
    }

    func testMergerDeduplicatesAndPrefersKnownLevel() {
        let now = Date()
        let withoutLevel = PeripheralBattery(
            id: "shared",
            name: "Mouse",
            kind: .mouse,
            level: nil,
            source: .hid,
            lastUpdated: now
        )
        let withLevel = PeripheralBattery(
            id: "shared",
            name: "Mouse",
            kind: .mouse,
            level: 0.5,
            state: .discharging,
            source: .gameController,
            lastUpdated: now.addingTimeInterval(-1)
        )

        let merged = BatteryMerger.merge([[withoutLevel], [withLevel]])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.level ?? 0, 0.5, accuracy: 0.001)
        XCTAssertEqual(merged.first?.state, .discharging)
    }

    func testMergerSortsLowBatteryFirstWithinKind() {
        let now = Date()
        let healthy = PeripheralBattery(
            id: "healthy",
            name: "Mouse A",
            kind: .mouse,
            level: 0.8,
            source: .hid,
            lastUpdated: now
        )
        let low = PeripheralBattery(
            id: "low",
            name: "Mouse B",
            kind: .mouse,
            level: 0.15,
            source: .hid,
            lastUpdated: now
        )

        let merged = BatteryMerger.merge([[healthy, low]])
        XCTAssertEqual(merged.map(\.id), ["low", "healthy"])
    }

    func testLowBatteryIgnoresChargingDevices() {
        let charging = PeripheralBattery(
            id: "charging",
            name: "Mouse",
            kind: .mouse,
            level: 0.1,
            state: .charging,
            source: .hid
        )
        XCTAssertFalse(charging.isLow)
        XCTAssertFalse(charging.isCritical)
    }
}
