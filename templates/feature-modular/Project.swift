import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.feature-modular",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: [.target(name: "ExampleFeature")]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.feature-modular-app-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "ExampleFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.example-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["ExampleFeature/Sources"],
            dependencies: []
        ),
        .target(
            name: "ExampleFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.example-feature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["ExampleFeature/Tests"],
            dependencies: [.target(name: "ExampleFeature")]
        ),
    ]
)
