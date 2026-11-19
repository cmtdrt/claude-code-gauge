// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClaudeCodeGauge",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeCodeGauge",
            path: "Sources/ClaudeCodeGauge"
        )
    ]
)
