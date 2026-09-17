import ProfileFeature
import SwiftUI

@main
struct ModularApp: App {
    var body: some Scene {
        WindowGroup {
            ProfileView(name: AppLaunchConfiguration.profileName)
        }
    }
}

enum AppLaunchConfiguration {
    static let profileName = "Taylor"
}
