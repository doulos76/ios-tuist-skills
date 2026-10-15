// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "LogKit": .staticFramework,
            "KeyValueStore": .staticFramework,
            "RetryKit": .staticFramework,
        ]
    )
#endif

let package = Package(
    name: "LargeGraphDependencies",
    dependencies: [
        .package(path: "../Packages/LogKit"),
        .package(path: "../Packages/KeyValueStore"),
        .package(path: "../Packages/RetryKit"),
    ]
)
