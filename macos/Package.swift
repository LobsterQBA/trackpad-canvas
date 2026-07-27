// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrackpadArchitect",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TrackpadArchitect", targets: ["TrackpadArchitect"])
    ],
    targets: [
        .target(name: "CMultitouchShim"),
        .executableTarget(
            name: "TrackpadArchitect",
            dependencies: ["CMultitouchShim"]
        ),
        .testTarget(
            name: "TrackpadArchitectTests",
            dependencies: ["TrackpadArchitect"]
        ),
    ]
)

