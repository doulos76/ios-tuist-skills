import ExampleFeature
import SwiftUI

@main
struct FeatureModularApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

struct AppRootView: View {
    var body: some View {
        ExampleFeatureView(name: AppConfiguration.defaultName)
    }
}

enum AppConfiguration {
    static let defaultName = "Tuist"
}
