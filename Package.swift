// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Leap",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Logging facade (apple/swift-log). The in-app console is a custom
        // LogHandler backend; see App/Logging.swift.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        // TOML parsing for the human-editable bindings document.
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "Leap",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "TOMLKit", package: "TOMLKit"),
            ],
            path: "Sources/Leap",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "LeapTests",
            dependencies: ["Leap"],
            path: "Tests/LeapTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
