import ProjectDescription

let project = Project(
    name: "RestyleCandidate",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.restyle-candidate",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Sources/**"],
            dependencies: [
                .target(name: "CleanFeature"),
                .target(name: "ExcludeFeature")
            ]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Tests/**"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "CleanFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-cleanfeature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["CleanFeature/Sources/**"],
            resources: ["CleanFeature/Resources/**"]
        ),
        .target(
            name: "CleanFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-cleanfeature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["CleanFeature/Tests/**"],
            dependencies: [.target(name: "CleanFeature")]
        ),
        .target(
            name: "ExcludeFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-excludefeature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [.glob("ExcludeFeature/Sources/**", excluding: ["ExcludeFeature/Sources/Preview/**"])]
        ),
        .target(
            name: "ExcludeFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-excludefeature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["ExcludeFeature/Tests/**"],
            dependencies: [.target(name: "ExcludeFeature")]
        )
    ]
)
