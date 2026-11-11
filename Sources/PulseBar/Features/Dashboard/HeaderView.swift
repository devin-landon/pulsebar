import SwiftUI

struct HeaderView: View {
    @Environment(\.isSnapshot) private var isSnapshot

    let deviceName: String
    let onOpenSettings: () -> Void
    let onOpenAbout: () -> Void
    let onQuit: () -> Void
    let onCollapse: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            PulseGlyph(size: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text("PulseBar")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Text.primary)

                Text(deviceName)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Text.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 4)

            LiveBadge()

            overflowMenu

            Button(action: onCollapse) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.Text.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("收起面板")
        }
    }

    @ViewBuilder
    private var overflowMenu: some View {
        if isSnapshot {
            Image(systemName: "ellipsis")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Text.secondary)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.white.opacity(0.06)))
        } else {
            Menu {
                Button("设置…", action: onOpenSettings)
                    .keyboardShortcut(",", modifiers: .command)
                Divider()
                Button("关于 PulseBar", action: onOpenAbout)
                Divider()
                Button("退出 PulseBar", action: onQuit)
                    .keyboardShortcut("q", modifiers: .command)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Text.secondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .contentShape(Circle())
            }
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

