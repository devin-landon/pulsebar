import SwiftUI

/// Design tokens for the whole app. Keep colors, radii and spacing here so the
/// dashboard and the settings window cannot drift apart.
enum Theme {
    enum Palette {
        static let backgroundTop = Color(hex: 0x16171C)
        static let backgroundBottom = Color(hex: 0x0B0C0F)
        static let cardTop = Color.white.opacity(0.065)
        static let cardBottom = Color.white.opacity(0.028)
        static let cardBorder = Color.white.opacity(0.07)
        static let divider = Color.white.opacity(0.06)
        static let track = Color.white.opacity(0.08)
    }

    enum Text {
        static let primary = Color.white.opacity(0.94)
        static let secondary = Color.white.opacity(0.56)
        static let tertiary = Color.white.opacity(0.32)
    }

    enum Accent {
        static let cpu = Color(hex: 0x4FD3E0)
        static let memory = Color(hex: 0xB18CFF)
        static let gpu = Color(hex: 0xFF6A9C)
        static let temperature = Color(hex: 0xFFB25C)
        static let disk = Color(hex: 0xFF9E45)
        static let network = Color(hex: 0x4DDB89)
        static let battery = Color(hex: 0x67E8B9)
        static let warning = Color(hex: 0xFF6B5E)
    }

    enum Metric {
        static let panelWidth: CGFloat = 360
        static let panelHeight: CGFloat = 648
        static let cardRadius: CGFloat = 18
        static let compactRadius: CGFloat = 11
        static let horizontalPadding: CGFloat = 13
        static let cardPadding: CGFloat = 13
        static let sectionSpacing: CGFloat = 10
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Snapshot mode

private struct SnapshotModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// `true` while rendering `--snapshot`; disables AppKit-backed controls that
    /// ImageRenderer cannot draw.
    var isSnapshot: Bool {
        get { self[SnapshotModeKey.self] }
        set { self[SnapshotModeKey.self] = newValue }
    }
}

