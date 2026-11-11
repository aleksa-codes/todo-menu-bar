// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "TodoMenuBar",
  platforms: [.macOS(.v14)],
  products: [.executable(name: "TodoMenuBar", targets: ["TodoMenuBar"])],
  targets: [
    .executableTarget(
      name: "TodoMenuBar",
      exclude: ["Resources"],
      swiftSettings: [.defaultIsolation(MainActor.self)]
    )
  ]
)
