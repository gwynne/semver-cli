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
import ArgumentParser

@main
struct Semver: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for performing various operations on semantic versions",
        subcommands: [CompareCommand.self, ParseCommand.self],
        defaultSubcommand: ParseCommand.self
    )
}
