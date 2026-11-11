import SwiftUI

// MARK: - Background

struct PanelBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.Palette.backgroundTop, Theme.Palette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Theme.Accent.cpu.opacity(0.12), .clear],
                center: UnitPoint(x: 0.08, y: 0.0),
                startRadius: 0,
                endRadius: 300
            )
            RadialGradient(
                colors: [Theme.Accent.memory.opacity(0.07), .clear],
                center: UnitPoint(x: 1.0, y: 0.42),
                startRadius: 0,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Card surface

private struct CardSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: Theme.Metric.cardRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Palette.cardTop, Theme.Palette.cardBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Metric.cardRadius, style: .continuous)
                    .strokeBorder(Theme.Palette.cardBorder, lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurfaceModifier())
    }
}

// MARK: - Brand

struct PulseGlyph: View {
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2EC8D8), Color(hex: 0x2268E8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                }

            PulseWave()
                .stroke(
                    Color.white.opacity(0.95),
                    style: StrokeStyle(
                        lineWidth: max(1.4, size * 0.05),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .padding(size * 0.24)
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.Accent.cpu.opacity(0.25), radius: 8, y: 3)
        .accessibilityHidden(true)
    }
}

struct PulseWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.52, y: rect.maxY - rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.66, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Small elements

struct LiveBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Theme.Accent.network)
                .frame(width: 5, height: 5)
                .overlay {
                    Circle()
                        .stroke(Theme.Accent.network.opacity(0.35), lineWidth: 3)
                        .scaleEffect(isPulsing ? 2.2 : 0.8)
                        .opacity(isPulsing ? 0 : 1)
                }
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                        isPulsing = true
                    }
                }

            Text("LIVE")
                .font(.system(size: 8, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(Theme.Text.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.white.opacity(0.06)))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5))
    }
}

struct ProgressBar: View {
    let value: Double?
    let accent: Color
    var height: CGFloat = 4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.track)

                if let value {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.62), accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(height, geometry.size.width * min(max(value, 0), 1)))
                }
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: value)
        .accessibilityHidden(true)
    }
}

struct BatteryGlyph: View {
    let level: Double?
    let isCharging: Bool

    var body: some View {
        HStack(spacing: 1.5) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .strokeBorder(tint.opacity(0.5), lineWidth: 1)

                RoundedRectangle(cornerRadius: 1.6, style: .continuous)
                    .fill(tint)
                    .frame(width: fillWidth, height: 5.5)
                    .padding(.leading, 2)

                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 23, height: 11)

            RoundedRectangle(cornerRadius: 0.8)
                .fill(tint.opacity(0.5))
                .frame(width: 1.5, height: 4.5)
        }
        .accessibilityHidden(true)
    }

    private var fillWidth: Double {
        max(1.5, 17 * (level ?? 0))
    }

    private var tint: Color {
        guard let level else { return Theme.Text.tertiary }
        if isCharging { return Theme.Accent.network }
        if level <= 0.1 { return Theme.Accent.warning }
        if level <= 0.2 { return Theme.Accent.temperature }
        return Theme.Accent.battery
    }
}

struct CardHeader: View {
    let symbol: String
    let title: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 13)

            Text(title)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.Text.secondary)
        }
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Palette.divider)
            .frame(height: 0.5)
    }
}

struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 8.5, weight: .semibold))
            .foregroundStyle(Theme.Text.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(Capsule().fill(Color.white.opacity(0.07)))
    }
}

struct SubtleIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.Text.secondary)
            .frame(width: 22, height: 22)
            .background(Circle().fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0.06)))
            .contentShape(Circle())
    }
}
