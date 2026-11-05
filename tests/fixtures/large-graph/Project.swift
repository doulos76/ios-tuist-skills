import ProjectDescription

let project = Project(
    name: "LargeGraph",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.large-graph",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: [
                .target(name: "HomeFeature"),
                .target(name: "SearchFeature"),
                .target(name: "ProfileFeature"),
                .target(name: "SettingsFeature"),
                .target(name: "CheckoutFeature"),
                .target(name: "CoreUtilities"),
                .target(name: "LegacyHelpers"),
            ]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.app-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "HomeFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.home-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["HomeFeature/Sources"],
            dependencies: [
                .target(name: "CatalogDomain"),
                .target(name: "CoreUI"),
                .target(name: "CoreAnalytics"),
            ]
        ),
        .target(
            name: "HomeFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.home-feature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["HomeFeature/Tests"],
            dependencies: [.target(name: "HomeFeature")]
        ),
        .target(
            name: "SearchFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.search-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["SearchFeature/Sources"],
            dependencies: [
                .target(name: "CatalogDomain"),
                .target(name: "CoreUI"),
                .target(name: "CoreNetworking"),
            ]
        ),
        .target(
            name: "ProfileFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.profile-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["ProfileFeature/Sources"],
            dependencies: [
                .target(name: "UserDomain"),
                .target(name: "CoreUI"),
            ]
        ),
        .target(
            name: "SettingsFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.settings-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["SettingsFeature/Sources"],
            dependencies: [
                .target(name: "UserDomain"),
                .target(name: "CoreUI"),
            ]
        ),
        .target(
            name: "CheckoutFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.checkout-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Checkout/**/*.swift"],
            dependencies: [
                .target(name: "OrderDomain"),
                .target(name: "CoreUI"),
            ]
        ),
        .target(
            name: "CheckoutFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.checkout-feature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["CheckoutTests/**/*.swift"],
            dependencies: [.target(name: "CheckoutFeature")]
        ),
        .target(
            name: "UserDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.user-domain",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["UserDomain/Sources"],
            dependencies: [
                .target(name: "CoreNetworking"),
                .target(name: "CorePersistence"),
            ]
        ),
        .target(
            name: "CatalogDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.catalog-domain",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CatalogDomain/Sources"],
            dependencies: [.target(name: "CoreNetworking")]
        ),
        .target(
            name: "CatalogDomainTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.catalog-domain-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CatalogDomain/Tests"],
            dependencies: [.target(name: "CatalogDomain")]
        ),
        .target(
            name: "OrderDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.order-domain",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["OrderDomain/Sources"],
            dependencies: [
                .target(name: "CoreNetworking"),
                .target(name: "CorePersistence"),
            ]
        ),
        .target(
            name: "CoreNetworking",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-networking",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreNetworking/Sources"],
            dependencies: [.external(name: "LogKit")]
        ),
        .target(
            name: "CoreNetworkingTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.core-networking-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreNetworking/Tests"],
            dependencies: [.target(name: "CoreNetworking")]
        ),
        .target(
            name: "CorePersistence",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-persistence",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CorePersistence/Sources"],
            dependencies: [.external(name: "KeyValueStore")]
        ),
        .target(
            name: "CoreUI",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-ui",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreUI/Sources"],
            dependencies: [.target(name: "DesignSystem")]
        ),
        .target(
            name: "CoreUtilities",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-utilities",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreUtilities/Sources"],
            dependencies: []
        ),
        .target(
            name: "CoreAnalytics",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-analytics",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreAnalytics/Sources"],
            dependencies: [.external(name: "LogKit")]
        ),
        .target(
            name: "DesignSystem",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.design-system",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["DesignSystem/Sources"],
            dependencies: []
        ),
        .target(
            name: "LegacyHelpers",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.example.legacy-helpers",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["LegacyHelpers/**/*.swift"],
            dependencies: [.target(name: "CoreUtilities")]
        ),
    ]
)
