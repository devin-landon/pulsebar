// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PulseBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PulseBar", targets: ["PulseBar"]),
        .library(name: "PulseBarCore", targets: ["PulseBarCore"]),
    ],
    targets: [
        .target(
            name: "PulseBarCore",
            path: "Sources/PulseBarCore"
        ),
        .executableTarget(
            name: "PulseBar",
            dependencies: ["PulseBarCore"],
            path: "Sources/PulseBar"
        ),
        .testTarget(
            name: "PulseBarCoreTests",
            dependencies: ["PulseBarCore"],
            path: "Tests/PulseBarCoreTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
