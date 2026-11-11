import XCTest
@testable import PulseBarCore

final class RateCalculatorTests: XCTestCase {
    func testFirstSampleReturnsNil() {
        var calculator = RateCalculator()
        let start = Date(timeIntervalSince1970: 1_000)

        XCTAssertNil(calculator.rate(bytes: 1_000, at: start))
        XCTAssertTrue(calculator.hasBaseline)
    }

    func testNormalDelta() {
        var calculator = RateCalculator()
        let start = Date(timeIntervalSince1970: 1_000)

        XCTAssertNil(calculator.rate(bytes: 1_000, at: start))
        let rate = calculator.rate(bytes: 3_000, at: start.addingTimeInterval(2))

        XCTAssertEqual(rate!, 1_000, accuracy: 0.001)
    }

    func testCounterResetReturnsNil() {
        var calculator = RateCalculator()
        let start = Date(timeIntervalSince1970: 1_000)

        _ = calculator.rate(bytes: 5_000, at: start)
        XCTAssertNil(calculator.rate(bytes: 100, at: start.addingTimeInterval(1)))
    }

    func testSleepSizedGapReturnsNilAndResetsBaseline() {
        var calculator = RateCalculator(maxElapsed: 10)
        let start = Date(timeIntervalSince1970: 1_000)

        _ = calculator.rate(bytes: 1_000, at: start)
        XCTAssertNil(calculator.rate(bytes: 50_000, at: start.addingTimeInterval(30)))

        // Next short interval after the gap can produce a rate again.
        let rate = calculator.rate(bytes: 51_000, at: start.addingTimeInterval(31))
        XCTAssertEqual(rate!, 1_000, accuracy: 0.001)
    }

    func testZeroOrNegativeElapsedReturnsNil() {
        var calculator = RateCalculator()
        let start = Date(timeIntervalSince1970: 1_000)

        _ = calculator.rate(bytes: 1_000, at: start)
        XCTAssertNil(calculator.rate(bytes: 2_000, at: start))
    }

    func testResetClearsBaseline() {
        var calculator = RateCalculator()
        let start = Date(timeIntervalSince1970: 1_000)

        _ = calculator.rate(bytes: 1_000, at: start)
        calculator.reset()
        XCTAssertFalse(calculator.hasBaseline)
        XCTAssertNil(calculator.rate(bytes: 2_000, at: start.addingTimeInterval(1)))
    }
}
