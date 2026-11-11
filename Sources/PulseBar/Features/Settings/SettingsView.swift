import PulseBarCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: AppPreferences
    @ObservedObject var battery: PeripheralBatteryMonitor
    @ObservedObject var store: DashboardStore

    var body: some View {
        ZStack {
            PanelBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    menuBarSection
                    batterySection
                    launchSection
                    aboutSection
                }
                .padding(20)
            }
        }
        .frame(width: 460, height: 580)
        .preferredColorScheme(.dark)
        .onAppear {
            preferences.refreshLoginItemStatus()
        }
        .onChange(of: preferences.refreshInterval) { _, newValue in
            store.setInterval(newValue)
        }
        .onChange(of: preferences.batteryPollingEnabled) { _, newValue in
            battery.setEnabled(newValue)
        }
        .onChange(of: preferences.batteryInterval) { _, newValue in
            battery.setInterval(newValue)
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 12) {
            PulseGlyph(size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("PulseBar 设置")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Text.primary)
                Text("系统监控 · 外设电量")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Text.secondary)
            }

            Spacer()

            Text("v\(AppEnvironment.version)")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.Text.tertiary)
        }
    }

    private var menuBarSection: some View {
        section("菜单栏") {
            row("显示内容", subtitle: "菜单栏图标旁的实时读数") {
                Picker("", selection: $preferences.menuBarMode) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 140)
            }

            Hairline()

            row("刷新频率", subtitle: "更高频率会增加少量 CPU 占用") {
                Picker("", selection: $preferences.refreshInterval) {
                    Text("1 秒").tag(1.0)
                    Text("2 秒").tag(2.0)
                    Text("5 秒").tag(5.0)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 170)
            }
        }
    }

    private var batterySection: some View {
        section("外设电量") {
            row("轮询电量", subtitle: "定时读取妙控设备与游戏手柄") {
                Toggle("", isOn: $preferences.batteryPollingEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Hairline()

            row("轮询间隔", subtitle: "电量变化较慢，30 秒通常足够") {
                Picker("", selection: $preferences.batteryInterval) {
                    Text("15 秒").tag(15.0)
                    Text("30 秒").tag(30.0)
                    Text("60 秒").tag(60.0)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 105)
                .disabled(!preferences.batteryPollingEnabled)
            }

            Hairline()

            Text("部分第三方蓝牙设备不会向 macOS 暴露电量；PulseBar 只显示系统能读到的值，不伪造读数。")
                .font(.system(size: 9))
                .foregroundStyle(Theme.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 10)
        }
    }

    private var launchSection: some View {
        section("启动") {
            row("登录时自动启动", subtitle: preferences.launchAtLoginDescription) {
                Toggle("", isOn: Binding(
                    get: { preferences.isLaunchAtLoginEnabled },
                    set: { preferences.setLaunchAtLogin($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
            }

            Hairline()

            HStack {
                Text("如状态显示“等待授权”，需要在系统设置中允许。")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Text.secondary)

                Spacer()

                Button("打开登录项…") {
                    preferences.openLoginItemsSettings()
                }
                .buttonStyle(.link)
                .font(.system(size: 9.5))
            }
            .padding(.vertical, 9)

            if let error = preferences.loginItemError {
                Text(error)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Accent.warning)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)
            }
        }
    }

    private var aboutSection: some View {
        section("关于") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("PulseBar \(AppEnvironment.version) (\(AppEnvironment.build))")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Theme.Text.primary)

                    Spacer()

                    Text("MIT License")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Text.tertiary)
                }

                Text("设计灵感来自 einsy1/pulse，独立实现；监控数据只在本机读取，不上传、不持久化。")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("源码与后续计划见项目 README 与 roadmap.md")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Text.tertiary)
            }
            .padding(.vertical, 10)
        }
    }

    // MARK: - Building blocks

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.Text.secondary)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
            .cardSurface()
        }
    }

    private func row<Control: View>(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Text.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            control()
        }
        .padding(.vertical, 9)
    }
}
