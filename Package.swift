// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "XSV",
    platforms: [.iOS(.v26), .macOS(.v26), .macCatalyst(.v26), .watchOS(.v26), .tvOS(.v26), .visionOS(.v26)],
    products: [
        .library(
            name: "XSV",
            targets: ["XSV"]
        ),
    ],
    targets: [
        .target(
            name: "XSV"
        ),
        .testTarget(
            name: "XSVTests",
            dependencies: ["XSV"]
        ),
    ],
    swiftLanguageModes: [.v6],
)
