// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MikePlayer",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MikePlayerCore"),
        .executableTarget(name: "MikePlayer", dependencies: ["MikePlayerCore"]),
        // XCTest and Swift Testing both need full Xcode; this runs with Command Line Tools only.
        .executableTarget(name: "MikePlayerChecks", dependencies: ["MikePlayerCore"]),
    ],
    swiftLanguageModes: [.v5]
)
