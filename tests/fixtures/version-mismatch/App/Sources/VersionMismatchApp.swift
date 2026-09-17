import SwiftUI

@main
struct VersionMismatchApp: App {
    var body: some Scene {
        WindowGroup {
            Text(SettingsTitle.value)
                .padding()
        }
    }
}

enum SettingsTitle {
    static let value = "Settings"
}
