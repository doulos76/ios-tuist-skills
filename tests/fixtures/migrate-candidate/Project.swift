import ProjectDescription

let project = Project(
    name: "MigrateCandidate",
    targets: [
        Target(
            name: "App",
            platform: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.migrate-candidate",
            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone]),
            infoPlist: .default,
            sources: ["App/Sources/**"]
        ),
        Target(
            name: "AppTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.migrate-candidate-tests",
            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone]),
            infoPlist: .default,
            sources: ["App/Tests/**"],
            dependencies: [
                .target(name: "App")
            ]
        )
    ]
)
