// swift-tools-version:5.2
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
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.2.2"),
        .package(url: "https://github.com/gwynne/swift-semver.git", from: "0.1.0-alpha"),
    ],
    targets: [
        .target(name: "semver", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "SwiftSemver", package: "swift-semver"),
        ]),
        .testTarget(name: "semverTests", dependencies: ["semver"]),
    ]
)
