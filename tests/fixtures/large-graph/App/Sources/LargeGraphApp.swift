import CheckoutFeature
import CoreUtilities
import HomeFeature
import LegacyHelpers
import ProfileFeature
import SearchFeature
import SettingsFeature
import SwiftUI

@main
struct LargeGraphApp: App {
    var body: some Scene {
        WindowGroup {
            Text(AppConfiguration.title)
        }
    }
}

enum AppConfiguration {
    static let title = TextUtilities.trimmed("  Large Graph  ")
}
