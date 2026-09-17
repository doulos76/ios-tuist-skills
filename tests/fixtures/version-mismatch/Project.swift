import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.version-mismatch",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            sources: ["App/Sources/**"],
            resources: [],
            dependencies: []
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.version-mismatch-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Tests/**"],
            resources: [],
            dependencies: [.target(name: "App")]
        ),
    ]
)
