import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.sample-minimal",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: []
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.sample-minimal-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
    ]
)
