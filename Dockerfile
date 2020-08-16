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

FROM swift:5.2-focal AS build
WORKDIR /build
COPY . .
RUN swift build --enable-test-discovery -c release

FROM swift:5.2-focal-slim
COPY --from=build /build/.build/release/semver /usr/bin
ENTRYPOINT ["/usr/bin/semver"]
CMD ["--help"]

