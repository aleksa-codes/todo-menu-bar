// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "TodoMenuBar",
  platforms: [.macOS(.v15)],
  products: [.executable(name: "TodoMenuBar", targets: ["TodoMenuBar"])],
  targets: [
    .executableTarget(
      name: "TodoMenuBar",
      exclude: ["Resources"],
      swiftSettings: [.defaultIsolation(MainActor.self)]
    )
  ]
)
