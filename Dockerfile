#===----------------------------------------------------------------------===//
#
# This source file is part of the semver-cli open source project
#
# Copyright (c) Gwynne Raskind
# Licensed under the MIT license
#
# See LICENSE.txt for license information
#
# SPDX-License-Identifier: MIT
#
#===----------------------------------------------------------------------===//

FROM swift:5.8-jammy AS build
WORKDIR /build
COPY . .
RUN swift build -c release --static-swift-stdlib

FROM ubuntu:jammy
COPY --from=build /build/.build/release/semver /usr/bin
ENTRYPOINT ["/usr/bin/semver"]
CMD ["--help"]
