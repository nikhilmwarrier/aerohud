// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AeroHUD",
    platforms: [
        .macOS(.v14) // Targets macOS Sonoma or later for modern SwiftUI
    ],
    targets: [
        .executableTarget(
            name: "aerohud",
            dependencies: []
        )
    ]
)
