import PulseBarCore
import SwiftUI

struct StorageCard: View {
    let snapshot: SystemSnapshot

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 6) {
                CardHeader(symbol: "internaldrive", title: "内置存储", accent: Theme.Accent.disk)
                Spacer()
                Text(usageText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.Text.secondary)
            }

            ProgressBar(value: snapshot.diskUsage, accent: Theme.Accent.disk, height: 5)

            HStack {
                Text("\(MetricFormatter.byteCount(snapshot.diskUsedBytes)) 已用")
                Spacer()
                Text("共 \(MetricFormatter.byteCount(snapshot.diskTotalBytes))")
            }
            .font(.system(size: 9.5))
            .foregroundStyle(Theme.Text.secondary)
        }
        .padding(Theme.Metric.cardPadding)
        .cardSurface()
    }

    private var usageText: String {
        guard let usage = snapshot.diskUsage else { return "不可用" }
        return "\(Int((usage * 100).rounded()))% 已用"
    }
}

struct NetworkCard: View {
    let snapshot: SystemSnapshot

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 6) {
                CardHeader(symbol: "globe", title: "网络速率", accent: Theme.Accent.network)
                Spacer()
                Text("当前")
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.Text.tertiary)
            }

            HStack(spacing: 10) {
                rateColumn(
                    symbol: "arrow.down",
                    label: "下载",
                    value: MetricFormatter.rate(snapshot.downloadBytesPerSecond),
                    accent: Theme.Accent.network
                )

                Rectangle()
                    .fill(Theme.Palette.divider)
                    .frame(width: 0.5, height: 30)

                rateColumn(
                    symbol: "arrow.up",
                    label: "上传",
                    value: MetricFormatter.rate(snapshot.uploadBytesPerSecond),
                    accent: Theme.Accent.cpu
                )
            }
        }
        .padding(Theme.Metric.cardPadding)
        .cardSurface()
    }

    private func rateColumn(
        symbol: String,
        label: String,
        value: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(accent)

                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Text.primary)
            }

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Theme.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
