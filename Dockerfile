FROM swift:5.2-focal AS build
WORKDIR /build
COPY . .
RUN swift build --enable-test-discovery -c release

FROM swift:5.2-focal-slim
COPY --from=build /build/.build/release/semver /usr/bin
ENTRYPOINT ["/usr/bin/semver"]
CMD ["--help"]

