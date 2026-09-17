import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.modular",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: [.target(name: "ProfileFeature")]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.modular-app-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "ProfileFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.profile-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["ProfileFeature/Sources"],
            dependencies: [.target(name: "SharedUI")]
        ),
        .target(
            name: "ProfileFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.profile-feature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["ProfileFeature/Tests"],
            dependencies: [.target(name: "ProfileFeature")]
        ),
        .target(
            name: "SharedUI",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.shared-ui",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["SharedUI/Sources"],
            dependencies: []
        ),
        .target(
            name: "SharedUITests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.shared-ui-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["SharedUI/Tests"],
            dependencies: [.target(name: "SharedUI")]
        ),
    ]
)
