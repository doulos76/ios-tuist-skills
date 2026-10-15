// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyValueStore",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KeyValueStore", targets: ["KeyValueStore"])],
    targets: [.target(name: "KeyValueStore")]
)
