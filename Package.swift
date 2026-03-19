// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DuckBar",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0"),
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "DuckBar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "HotKey", package: "HotKey")
            ],
            path: "Sources/DuckBar",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
            ]
        )
    ]
)
