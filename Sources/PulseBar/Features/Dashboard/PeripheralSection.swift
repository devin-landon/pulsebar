import PulseBarCore
import SwiftUI

struct PeripheralSection: View {
    @ObservedObject var monitor: PeripheralBatteryMonitor

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                CardHeader(
                    symbol: "dot.radiowaves.left.and.right",
                    title: "外设电量",
                    accent: Theme.Accent.battery
                )

                if !monitor.devices.isEmpty {
                    CountBadge(count: monitor.devices.count)
                }

                Spacer()

                if monitor.isEnabled {
                    Button {
                        monitor.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(SubtleIconButtonStyle())
                    .help("刷新外设电量")
                } else {
                    Text("已暂停")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }

            if monitor.devices.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(monitor.devices) { device in
                        PeripheralRow(device: device)
                        if device.id != monitor.devices.last?.id {
                            Hairline()
                        }
                    }
                }
            }
        }
        .padding(Theme.Metric.cardPadding)
        .cardSurface()
    }

    private var emptyState: some View {
        VStack(spacing: 5) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Theme.Text.tertiary)

            Text("未发现可读取电量的外设")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.Text.secondary)

            Text("妙控系列与游戏手柄支持较好；部分第三方蓝牙设备不公开电量。")
                .font(.system(size: 9))
                .foregroundStyle(Theme.Text.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

private struct PeripheralRow: View {
    let device: PeripheralBattery

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconColor.opacity(0.12))

                Image(systemName: device.kind.symbolName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(device.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Text.primary)
                    .lineLimit(1)

                Text("\(device.kind.displayName) · \(device.source.displayName)")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Text.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if device.isLow {
                Text("低")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.Accent.warning)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Theme.Accent.warning.opacity(0.14)))
            }

            Text(MetricFormatter.battery(device.level))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(batteryTextColor)
                .frame(minWidth: 34, alignment: .trailing)

            BatteryGlyph(level: device.level, isCharging: device.state == .charging)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(device.name)，\(device.kind.displayName)，电量 \(MetricFormatter.battery(device.level))"
        )
    }

    private var iconColor: Color {
        if device.isLow { return Theme.Accent.warning }
        if device.state == .charging { return Theme.Accent.network }
        return Theme.Accent.battery
    }

    private var batteryTextColor: Color {
        if device.level == nil { return Theme.Text.tertiary }
        if device.isLow { return Theme.Accent.warning }
        return Theme.Text.primary
    }
}

struct FooterView: View {
    let refreshInterval: TimeInterval
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.Accent.network)
                .frame(width: 4, height: 4)

            Text(refreshText)
                .font(.system(size: 9))
                .foregroundStyle(Theme.Text.secondary)

            Spacer()

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Self.timeFormatter.string(from: context.date))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Text.secondary)
            }

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(SubtleIconButtonStyle())
            .help("打开设置")
        }
        .padding(.horizontal, 2)
        .padding(.top, 1)
    }

    private var refreshText: String {
        if refreshInterval >= 5 { return "每 5 秒刷新" }
        if refreshInterval >= 2 { return "每 2 秒刷新" }
        return "每秒刷新"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
