// swift-tools-version:5.7
//===----------------------------------------------------------------------===//
//
// This source file is part of the semver-cli open source project
//
// Copyright (c) Gwynne Raskind
// Licensed under the MIT license
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//
import PackageDescription

let package = Package(
    name: "semver-cli",
    products: [
        .executable(name: "semver", targets: ["semver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/gwynne/swift-semver.git", from: "1.0.0-beta"),
    ],
    targets: [
        .executableTarget(name: "semver", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "SwiftSemver", package: "swift-semver"),
        ]),
        .testTarget(name: "semverTests", dependencies: ["semver"]),
    ]
)
