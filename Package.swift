// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "XSV",
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
