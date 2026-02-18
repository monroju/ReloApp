// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ReloApp",
    platforms: [
        .iOS(.v18),
    ],
    targets: [
        .executableTarget(
            name: "ReloApp",
            path: "Sources",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
)
