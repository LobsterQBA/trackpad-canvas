// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrackpadCanvas",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TrackpadCanvas", targets: ["TrackpadArchitect"])
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
