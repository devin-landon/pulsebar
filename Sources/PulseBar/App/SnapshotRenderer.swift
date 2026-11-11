import AppKit
import PulseBarCore
import SwiftUI

/// Renders the dashboard to a PNG without showing the UI.
/// Used by `swift run PulseBar --snapshot docs/images/dashboard.png`.
@MainActor
enum SnapshotRenderer {
    static var requestedPath: String? {
        guard let index = CommandLine.arguments.firstIndex(of: "--snapshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return CommandLine.arguments[index + 1]
    }

    @discardableResult
    static func render(to path: String) -> Bool {
        _ = NSApplication.shared

        let battery = PeripheralBatteryMonitor(
            providers: [DemoBatteryProvider()],
            interval: 30
        )
        let store = DashboardStore(
            metrics: DemoMetricsProvider(),
            battery: battery,
            interval: 1
        )
        store.sample()
        battery.refresh()

        let content = DashboardContent(
            store: store,
            onOpenSettings: {},
            onOpenAbout: {},
            onQuit: {},
            onCollapse: {}
        )
        .padding(.horizontal, Theme.Metric.horizontalPadding)
        .padding(.top, 13)
        .padding(.bottom, 12)
        .background(PanelBackground())
        .frame(width: Theme.Metric.panelWidth)
        .environment(\.colorScheme, .dark)
        .environment(\.isSnapshot, true)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }

        do {
            let url = URL(fileURLWithPath: path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try png.write(to: url)
            return true
        } catch {
            return false
        }
    }
}
