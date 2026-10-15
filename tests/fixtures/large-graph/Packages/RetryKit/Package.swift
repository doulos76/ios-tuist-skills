// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RetryKit",
    platforms: [.iOS(.v17)],
    products: [.library(name: "RetryKit", targets: ["RetryKit"])],
    targets: [.target(name: "RetryKit")]
)
