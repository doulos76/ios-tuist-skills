import SwiftUI
import LogKit

@main
struct ExtractCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            SettingsRow(title: "Notifications", isOn: true)
        }
    }
}
