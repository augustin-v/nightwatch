// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AuroraCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "AuroraCore", targets: ["AuroraCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AuroraCore",
            dependencies: []
        ),
        .testTarget(
            name: "AuroraCoreTests",
            dependencies: ["AuroraCore"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
