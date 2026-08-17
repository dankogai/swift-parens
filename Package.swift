// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-parens",
    products: [
        .library(name: "Parens", targets: ["Parens"]),
        .executable(name: "parens", targets: ["ParensCLI"]),
    ],
    targets: [
        .target(name: "Parens"),
        .executableTarget(name: "ParensCLI", dependencies: ["Parens"]),
        .testTarget(name: "ParensTests", dependencies: ["Parens"]),
    ]
)
