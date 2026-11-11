import Darwin
import Foundation
import IOKit

// MARK: - CPU

/// Aggregates per-core CPU tick deltas into a single 0...1 utilization value.
/// Must only be accessed from the metrics serial queue (`MetricsScheduler`).
final class CPUSampler {
    private var previousTicks: [UInt32]?

    func sample() -> Double? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        guard host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &info,
            &infoCount
        ) == KERN_SUCCESS, let info else {
            return nil
        }

        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        let stateCount = Int(CPU_STATE_MAX)
        var ticks = [UInt32]()
        ticks.reserveCapacity(Int(cpuCount) * stateCount)

        for cpu in 0..<Int(cpuCount) {
            let base = cpu * stateCount
            ticks.append(UInt32(bitPattern: info[base + Int(CPU_STATE_USER)]))
            ticks.append(UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)]))
            ticks.append(UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)]))
            ticks.append(UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)]))
        }

        let previous = previousTicks
        previousTicks = ticks

        guard let previous else { return nil }
        return CPUTickAccumulator.utilization(previous: previous, current: ticks)
    }

    func reset() {
        previousTicks = nil
    }
}

// MARK: - Memory

final class MemorySampler {
    struct Reading {
        var usage: Double?
        var used: UInt64?
        var total: UInt64?
    }

    func sample() -> Reading {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else {
            return Reading(usage: nil, used: nil, total: nil)
        }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        // Approximates Activity Monitor's "Memory Used": wired + active + compressed.
        let pages = UInt64(stats.active_count)
            + UInt64(stats.wire_count)
            + UInt64(stats.compressor_page_count)
        let total = ProcessInfo.processInfo.physicalMemory
        let used = min(pages * UInt64(pageSize), total)
        let usage = total > 0 ? Double(used) / Double(total) : nil

        return Reading(usage: usage, used: used, total: total)
    }
}

// MARK: - Disk

final class DiskSampler {
    func sample() -> (used: UInt64?, total: UInt64?) {
        let url = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
        ]
        guard let values = try? url.resourceValues(forKeys: keys),
              let capacity = values.volumeTotalCapacity,
              capacity > 0 else {
            return (nil, nil)
        }

        let available = values.volumeAvailableCapacityForImportantUsage ?? 0
        let used = max(Int64(capacity) - available, 0)
        return (UInt64(used), UInt64(capacity))
    }
}

// MARK: - Network

/// Must only be accessed from the metrics serial queue (`MetricsScheduler`).
final class NetworkSampler {
    private var downloadRate = RateCalculator()
    private var uploadRate = RateCalculator()

    func sample() -> (download: Double?, upload: Double?) {
        var totalReceived: UInt64 = 0
        var totalSent: UInt64 = 0

        var addressList: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addressList) == 0, let first = addressList else {
            return (nil, nil)
        }
        defer { freeifaddrs(first) }

        // Virtual/VPN interfaces double-count traffic against the physical link.
        let ignoredPrefixes = ["lo", "utun", "awdl", "llw", "bridge", "gif", "stf", "anpi", "ap"]
        var cursor = first
        while true {
            let entry = cursor.pointee
            if let address = entry.ifa_addr,
               address.pointee.sa_family == UInt8(AF_LINK),
               entry.ifa_flags & UInt32(IFF_UP) != 0,
               let data = entry.ifa_data {
                let name = String(cString: entry.ifa_name)
                if !ignoredPrefixes.contains(where: { name.hasPrefix($0) }) {
                    let interfaceData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalReceived += UInt64(interfaceData.ifi_ibytes)
                    totalSent += UInt64(interfaceData.ifi_obytes)
                }
            }
            guard let next = entry.ifa_next else { break }
            cursor = next
        }

        let now = Date()
        let download = downloadRate.rate(bytes: totalReceived, at: now)
        let upload = uploadRate.rate(bytes: totalSent, at: now)
        return (download, upload)
    }

    func reset() {
        downloadRate.reset()
        uploadRate.reset()
    }
}

// MARK: - GPU

final class GPUSampler {
    func sample() -> Double? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOAccelerator"),
            &iterator
        ) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var values: [Double] = []
        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            defer { IOObjectRelease(service) }

            guard let property = IORegistryEntryCreateCFProperty(
                service,
                "PerformanceStatistics" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue(),
                let stats = property as? [String: Any],
                let number = stats["Device Utilization %"] as? NSNumber else {
                continue
            }
            values.append(number.doubleValue)
        }

        guard let maximum = values.max() else { return nil }
        return min(max(maximum / 100, 0), 1)
    }
}

// MARK: - Temperature

final class TemperatureSampler {
    /// M2: read the PMU / pACC sensors through IOHIDEventSystemClient.
    /// The private symbols are documented in `docs/battery-research.md` and the roadmap.
    func sample() -> Double? {
        nil
    }
}
