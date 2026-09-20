import ProjectDescription

let project = Project(
    name: "ScaffoldCandidate",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.scaffold-candidate",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Sources/**"]
        )
    ]
)
