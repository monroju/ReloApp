// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ReloApp",
    platforms: [
        .iOS(.v17),
    ],
    targets: [
        .executableTarget(
            name: "ReloApp",
            path: "Sources"
        ),
    ]
)
