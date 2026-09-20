import ProjectDescription

let project = Project(
    name: "TestTargetCandidate",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.test-target-candidate",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Sources/**"],
            dependencies: [
                .target(name: "FeatureA"),
                .target(name: "FeatureB")
            ]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Tests/**"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "FeatureA",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featurea",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureA/Sources/**"]
        ),
        .target(
            name: "FeatureATests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featurea-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureA/Tests/**"],
            dependencies: [.target(name: "FeatureA")]
        ),
        .target(
            name: "FeatureB",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featureb",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureB/Sources/**"]
        )
    ],
    schemes: [
        .scheme(
            name: "App",
            shared: true,
            buildAction: .buildAction(targets: ["App", "FeatureA", "FeatureB"]),
            testAction: .targets(["AppTests", "FeatureATests"]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
