// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AeroHUD",
    platforms: [
        .macOS(.v11) 
    ],
    targets: [
        .executableTarget(
            name: "aerohud",
            dependencies: []
        )
    ]
)
