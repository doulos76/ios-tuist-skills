// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LogKit",
    platforms: [.iOS(.v17)],
    products: [.library(name: "LogKit", targets: ["LogKit"])],
    targets: [.target(name: "LogKit")]
)
