// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "semver-cli",
    products: [
        .executable(name: "semver", targets: ["semver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.2.2"),
    ],
    targets: [
        .target(name: "semver", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .testTarget(name: "semverTests", dependencies: ["semver"]),
    ]
)
