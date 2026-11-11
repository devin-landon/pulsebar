import XCTest
@testable import PulseBarCore

final class MetricsSchedulerTests: XCTestCase {
    func testStartDeliversSample() {
        let provider = CountingMetricsProvider()
        let scheduler = MetricsScheduler(
            provider: provider,
            interval: 60,
            queue: DispatchQueue(label: "test.metrics")
        )
        let expectation = expectation(description: "sample delivered")

        scheduler.start { snapshot in
            XCTAssertFalse(snapshot.isInitial)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
        scheduler.stop()
        XCTAssertGreaterThanOrEqual(provider.sampleCount, 1)
    }

    func testSetIntervalDoesNotStackTimers() {
        let provider = CountingMetricsProvider()
        let queue = DispatchQueue(label: "test.metrics.interval")
        let scheduler = MetricsScheduler(provider: provider, interval: 60, queue: queue)
        let first = expectation(description: "first sample")

        scheduler.start { _ in
            first.fulfill()
        }
        wait(for: [first], timeout: 2)

        let before = provider.sampleCount
        scheduler.setInterval(30)
        scheduler.setInterval(45)
        scheduler.setInterval(60)

        let flushed = expectation(description: "flush")
        queue.async { flushed.fulfill() }
        wait(for: [flushed], timeout: 1)

        // Repeating interval is still long; only the start sample should exist.
        XCTAssertEqual(provider.sampleCount, before)
        scheduler.stop()
    }

    func testRequestSampleWhileStoppedIsNoOp() {
        let provider = CountingMetricsProvider()
        let queue = DispatchQueue(label: "test.metrics.stopped")
        let scheduler = MetricsScheduler(provider: provider, interval: 60, queue: queue)

        scheduler.requestSample()

        let flushed = expectation(description: "flush")
        queue.async { flushed.fulfill() }
        wait(for: [flushed], timeout: 1)

        XCTAssertEqual(provider.sampleCount, 0)
    }

    func testResumeSamplesAfterPause() {
        let provider = CountingMetricsProvider()
        let queue = DispatchQueue(label: "test.metrics.pause")
        let scheduler = MetricsScheduler(provider: provider, interval: 60, queue: queue)
        let first = expectation(description: "start sample")
        first.assertForOverFulfill = false

        scheduler.start { _ in
            first.fulfill()
        }
        wait(for: [first], timeout: 2)

        scheduler.pause()
        let paused = expectation(description: "paused")
        queue.async { paused.fulfill() }
        wait(for: [paused], timeout: 1)

        let beforeResume = provider.sampleCount
        scheduler.resume()

        let deadline = Date().addingTimeInterval(2)
        while provider.sampleCount <= beforeResume, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
        XCTAssertGreaterThan(provider.sampleCount, beforeResume)
        scheduler.stop()
    }
}

/// Deterministic provider that counts how often `sample()` runs.
private final class CountingMetricsProvider: SystemMetricsProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var _sampleCount = 0

    var sampleCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _sampleCount
    }

    func sample() -> SystemSnapshot {
        lock.lock()
        _sampleCount += 1
        lock.unlock()
        return SystemSnapshot(
            cpuUsage: 0.1,
            memoryUsage: 0.2,
            sampledAt: Date()
        )
    }
}
