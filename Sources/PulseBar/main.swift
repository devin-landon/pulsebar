import AppKit

if let path = MainActor.assumeIsolated({ SnapshotRenderer.requestedPath }) {
    let success = MainActor.assumeIsolated { SnapshotRenderer.render(to: path) }
    print(success ? "Wrote snapshot to \(path)" : "Failed to render snapshot")
    exit(success ? 0 : 1)
}

MainActor.assumeIsolated {
    let application = NSApplication.shared
    application.delegate = AppDelegate.shared
    application.setActivationPolicy(.accessory)
    application.run()
}
