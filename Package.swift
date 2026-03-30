// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftTextMeasure",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "SwiftTextMeasure", targets: ["SwiftTextMeasure"]),
    ],
    targets: [
        .target(name: "SwiftTextMeasure"),
        .testTarget(name: "SwiftTextMeasureTests", dependencies: ["SwiftTextMeasure"]),
        .executableTarget(
            name: "DemoApp",
            dependencies: ["SwiftTextMeasure"],
            path: "DemoApp"
        ),
    ]
)
