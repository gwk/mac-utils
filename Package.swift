// swift-tools-version:5.5
// Dedicated to the public domain under CC0: https://creativecommons.org/publicdomain/zero/1.0/.


import PackageDescription

let package = Package(
  name: "mac-utils",
  platforms: [.macOS(.v11)],
  products: [
    .executable(name: "del", targets: ["del"]),
    .executable(name: "zapple", targets: ["zapple"]),
  ],
  targets: [
    .executableTarget(name: "del", path: "src/del"),
    .executableTarget(name: "gen-thumbnails", path: "src/gen-thumbnails"),
    .executableTarget(name: "zapple", path: "src/zapple"),
  ],
  swiftLanguageVersions: [.v5]
)
