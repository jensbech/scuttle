// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Scuttle",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "ScuttleCore"),
        .target(name: "ScuttleRender", dependencies: ["ScuttleCore"]),
        .executableTarget(
            name: "Scuttle",
            dependencies: ["ScuttleCore", "ScuttleRender"]
        ),
        .executableTarget(
            name: "ScuttleSnap",
            dependencies: ["ScuttleCore", "ScuttleRender"]
        ),
        .testTarget(name: "ScuttleCoreTests", dependencies: ["ScuttleCore"]),
    ]
)
