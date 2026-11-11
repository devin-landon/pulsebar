import XCTest
@testable import PulseBarCore

final class MetricFormatterTests: XCTestCase {
    func testPercent() {
        XCTAssertEqual(MetricFormatter.percent(0.264), "26")
        XCTAssertEqual(MetricFormatter.percent(0.999), "100")
        XCTAssertEqual(MetricFormatter.percent(1.4), "100")
        XCTAssertEqual(MetricFormatter.percent(nil), "—")
    }

    func testPercentInt() {
        XCTAssertEqual(MetricFormatter.percentInt(0.264), 26)
        XCTAssertNil(MetricFormatter.percentInt(nil))
    }

    func testRates() {
        XCTAssertEqual(MetricFormatter.rate(7_200), "7.2 KB/s")
        XCTAssertEqual(MetricFormatter.rate(4_100), "4.1 KB/s")
        XCTAssertEqual(MetricFormatter.rate(0), "0 B/s")
        XCTAssertEqual(MetricFormatter.rate(nil), "—")
    }

    func testByteCountUsesDecimalUnits() {
        XCTAssertEqual(MetricFormatter.byteCount(189_400_000_000), "189.4 GB")
        XCTAssertEqual(MetricFormatter.byteCount(245_000_000_000), "245.0 GB")
        XCTAssertEqual(MetricFormatter.byteCount(nil), "—")
    }

    func testBattery() {
        XCTAssertEqual(MetricFormatter.battery(0.78), "78%")
        XCTAssertEqual(MetricFormatter.battery(0), "0%")
        XCTAssertEqual(MetricFormatter.battery(nil), "—")
    }

    func testTemperature() {
        XCTAssertEqual(MetricFormatter.temperature(64.4), "64")
        XCTAssertEqual(MetricFormatter.temperature(nil), "—")
    }
}
