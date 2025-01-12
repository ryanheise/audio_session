// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "audio_session",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "audio-session", targets: ["audio_session"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "audio_session",
            dependencies: [],
            cSettings: [
                .headerSearchPath("include/audio_session")
            ]
        )
    ]
)
