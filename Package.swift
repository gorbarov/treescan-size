// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TreeSize",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "tscan", targets: ["tscan"]),
        .executable(name: "TreeSizeApp", targets: ["TreeSizeApp"]),
    ],
    targets: [
        .target(name: "TreeSizeCore"),
        .executableTarget(name: "tscan", dependencies: ["TreeSizeCore"]),
        .executableTarget(name: "TreeSizeApp", dependencies: ["TreeSizeCore"]),
    ]
)
