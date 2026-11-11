import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: DashboardStore

    let onOpenSettings: () -> Void
    let onOpenAbout: () -> Void
    let onQuit: () -> Void
    let onCollapse: () -> Void

    var body: some View {
        ZStack {
            PanelBackground()

            ScrollView(.vertical, showsIndicators: false) {
                DashboardContent(
                    store: store,
                    onOpenSettings: onOpenSettings,
                    onOpenAbout: onOpenAbout,
                    onQuit: onQuit,
                    onCollapse: onCollapse
                )
                .padding(.horizontal, Theme.Metric.horizontalPadding)
                .padding(.top, 13)
                .padding(.bottom, 12)
            }
        }
        .frame(width: Theme.Metric.panelWidth, height: Theme.Metric.panelHeight)
        .preferredColorScheme(.dark)
        .onAppear {
            store.sample()
            store.battery.refresh()
        }
    }
}

/// Scroll-free dashboard body, also used by `--snapshot`.
struct DashboardContent: View {
    @ObservedObject var store: DashboardStore

    let onOpenSettings: () -> Void
    let onOpenAbout: () -> Void
    let onQuit: () -> Void
    let onCollapse: () -> Void

    var body: some View {
        VStack(spacing: Theme.Metric.sectionSpacing) {
            HeaderView(
                deviceName: store.deviceName,
                onOpenSettings: onOpenSettings,
                onOpenAbout: onOpenAbout,
                onQuit: onQuit,
                onCollapse: onCollapse
            )

            SystemPulseCard(snapshot: store.snapshot)
            StorageCard(snapshot: store.snapshot)
            NetworkCard(snapshot: store.snapshot)
            PeripheralSection(monitor: store.battery)

            FooterView(
                refreshInterval: store.refreshInterval,
                onOpenSettings: onOpenSettings
            )
        }
    }
}
