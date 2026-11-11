import PulseBarCore
import SwiftUI

struct SystemPulseCard: View {
    let snapshot: SystemSnapshot

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                MetricTile(
                    title: "CPU",
                    symbol: "cpu",
                    accent: Theme.Accent.cpu,
                    value: MetricFormatter.percent(snapshot.cpuUsage),
                    unit: "%",
                    progress: snapshot.cpuUsage
                )
                MetricTile(
                    title: "内存",
                    symbol: "memorychip",
                    accent: Theme.Accent.memory,
                    value: MetricFormatter.percent(snapshot.memoryUsage),
                    unit: "%",
                    progress: snapshot.memoryUsage
                )
            }

            HStack(alignment: .top, spacing: 16) {
                MetricTile(
                    title: "GPU",
                    symbol: "display",
                    accent: Theme.Accent.gpu,
                    value: MetricFormatter.percent(snapshot.gpuUsage),
                    unit: "%",
                    progress: snapshot.gpuUsage
                )
                MetricTile(
                    title: "CPU 温度",
                    symbol: "thermometer.medium",
                    accent: Theme.Accent.temperature,
                    value: MetricFormatter.temperature(snapshot.cpuTemperatureCelsius),
                    unit: "°C",
                    progress: snapshot.cpuTemperatureCelsius.map { min(max($0 / 100, 0), 1) }
                )
            }
        }
        .padding(Theme.Metric.cardPadding)
        .cardSurface()
    }
}

private struct MetricTile: View {
    let title: String
    let symbol: String
    let accent: Color
    let value: String
    let unit: String?
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(accent)

                Text(title)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.Text.secondary)

                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(value == "—" ? Theme.Text.tertiary : Theme.Text.primary)
                    .contentTransition(.numericText())

                if let unit {
                    Text(unit)
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.Text.secondary)
                }
            }
            .frame(height: 30, alignment: .leading)

            ProgressBar(value: progress, accent: accent, height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
