// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "XSV",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "XSV",
            targets: ["XSV"]
        ),
    ],
    targets: [
        .target(
            name: "XSV",
        ),
        .testTarget(
            name: "XSVTests",
            dependencies: ["XSV"],
            resources: [
                .process("Data")
            ],
        ),
    ],
    swiftLanguageModes: [.v6],
)
