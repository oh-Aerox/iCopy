// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iCopy",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "iCopy",
            path: "Sources",
            swiftSettings: [
                // AppKit UI stays on the main thread; Swift 6 isolation adds no safety here.
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)
