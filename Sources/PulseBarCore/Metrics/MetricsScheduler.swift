import Foundation

/// Owns the metrics provider on a dedicated serial queue so CPU/network sampler
/// state is never touched from the main thread.
///
/// Timers are `DispatchSourceTimer`s on that queue: `start` / `stop` /
/// `setInterval` / `requestSample` all serialize through the same context, so
/// panel toggles and preference changes cannot create duplicate timers or races.
public final class MetricsScheduler: @unchecked Sendable {
    public typealias SampleHandler = @Sendable (SystemSnapshot) -> Void

    private let queue: DispatchQueue
    private let provider: SystemMetricsProviding

    private var interval: TimeInterval
    private var timer: DispatchSourceTimer?
    private var onSample: SampleHandler?
    private var isRunning = false
    private var isPaused = false
    /// Bumped on every `stop` so in-flight work drops stale results.
    private var generation = 0

    public init(
        provider: SystemMetricsProviding,
        interval: TimeInterval = 1,
        queue: DispatchQueue? = nil
    ) {
        self.provider = provider
        self.interval = max(0.5, interval)
        self.queue = queue ?? DispatchQueue(
            label: "com.dvnlandon.pulsebar.metrics",
            qos: .utility
        )
    }

    public var refreshInterval: TimeInterval {
        queue.sync { interval }
    }

    public var isActive: Bool {
        queue.sync { isRunning && !isPaused }
    }

    /// Starts periodic sampling. Replacing an existing handler cancels the
    /// previous timer first — never stacks timers.
    public func start(onSample: @escaping SampleHandler) {
        queue.async { [weak self] in
            guard let self else { return }
            self.onSample = onSample
            self.isRunning = true
            self.isPaused = false
            self.rescheduleLocked()
            self.performSampleLocked()
        }
    }

    public func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.generation &+= 1
            self.isRunning = false
            self.isPaused = false
            self.cancelTimerLocked()
            self.onSample = nil
        }
    }

    /// Pause the timer without clearing the handler (sleep). Wake via `resume()`.
    public func pause() {
        queue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.isPaused = true
            self.cancelTimerLocked()
        }
    }

    /// Resume after pause and take one immediate sample (wake).
    public func resume() {
        queue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.isPaused = false
            self.rescheduleLocked()
            self.performSampleLocked()
        }
    }

    public func setInterval(_ newValue: TimeInterval) {
        let clamped = max(0.5, newValue)
        queue.async { [weak self] in
            guard let self else { return }
            guard clamped != self.interval else { return }
            self.interval = clamped
            guard self.isRunning, !self.isPaused else { return }
            self.rescheduleLocked()
        }
    }

    /// Request an out-of-band sample (panel open). Coalesces on the serial queue.
    public func requestSample() {
        queue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.performSampleLocked()
        }
    }

    // MARK: - Private (queue-only)

    private func rescheduleLocked() {
        cancelTimerLocked()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        let interval = self.interval
        timer.schedule(
            deadline: .now() + interval,
            repeating: interval,
            leeway: .milliseconds(Int(min(150, interval * 100)))
        )

        let capturedGeneration = generation
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard self.generation == capturedGeneration else { return }
            guard self.isRunning, !self.isPaused else { return }
            self.performSampleLocked()
        }

        self.timer = timer
        timer.resume()
    }

    private func cancelTimerLocked() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
    }

    private func performSampleLocked() {
        let capturedGeneration = generation
        let snapshot = provider.sample()
        guard generation == capturedGeneration, isRunning else { return }
        onSample?(snapshot)
    }
}
