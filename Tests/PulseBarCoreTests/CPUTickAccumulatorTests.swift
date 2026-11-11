import XCTest
@testable import PulseBarCore

final class CPUTickAccumulatorTests: XCTestCase {
    func testWrappingDelta() {
        XCTAssertEqual(CPUTickAccumulator.delta(current: 5, previous: 3), 2)
        XCTAssertEqual(CPUTickAccumulator.delta(current: 0, previous: UInt32.max), 1)
        XCTAssertEqual(
            CPUTickAccumulator.delta(current: 10, previous: UInt32.max - 5),
            16
        )
    }

    func testUtilizationBusyFraction() {
        // One core: previous idle-heavy → current with user/system work.
        let previous: [UInt32] = [10, 5, 100, 0]
        let current: [UInt32] = [20, 15, 110, 0]
        // busy = 10+10+0 = 20, total = 20+10 = 30 → 2/3
        let usage = CPUTickAccumulator.utilization(previous: previous, current: current)
        XCTAssertEqual(usage!, 20.0 / 30.0, accuracy: 0.0001)
    }

    func testAllIdleReturnsZero() {
        let previous: [UInt32] = [1, 1, 10, 0]
        let current: [UInt32] = [1, 1, 40, 0]
        XCTAssertEqual(CPUTickAccumulator.utilization(previous: previous, current: current)!, 0)
    }

    func testAllZeroTicksReturnsNil() {
        let ticks = [UInt32](repeating: 0, count: 4)
        XCTAssertNil(CPUTickAccumulator.utilization(previous: ticks, current: ticks))
    }

    func testMismatchedLengthsReturnNil() {
        XCTAssertNil(
            CPUTickAccumulator.utilization(
                previous: [1, 2, 3, 4],
                current: [1, 2, 3, 4, 5, 6, 7, 8]
            )
        )
    }

    func testEmptyReturnsNil() {
        XCTAssertNil(CPUTickAccumulator.utilization(previous: [], current: []))
    }

    func testWrapAcrossCores() {
        let previous: [UInt32] = [UInt32.max - 1, 0, 0, 0]
        let current: [UInt32] = [5, 0, 0, 0]
        // delta user = 7, total = 7 → 1.0
        XCTAssertEqual(
            CPUTickAccumulator.utilization(previous: previous, current: current)!,
            1.0,
            accuracy: 0.0001
        )
    }
}
