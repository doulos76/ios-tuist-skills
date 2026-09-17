import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.architecture-smells",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: [.target(name: "FeatureA")]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.architecture-smells-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "FeatureA",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.architecture-smells-feature-a",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["FeatureA/Sources"],
            dependencies: [.target(name: "CoreKit")]
        ),
        .target(
            name: "FeatureATests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.architecture-smells-feature-a-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["FeatureA/Tests"],
            dependencies: [.target(name: "FeatureA")]
        ),
        .target(
            name: "CoreKit",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.architecture-smells-core-kit",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreKit/Sources"],
            dependencies: []
        ),
        .target(
            name: "CoreKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.architecture-smells-core-kit-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreKit/Tests"],
            dependencies: [.target(name: "CoreKit")]
        ),
    ]
)
