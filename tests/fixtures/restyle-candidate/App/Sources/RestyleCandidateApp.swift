import SwiftUI
import CleanFeature
import ExcludeFeature

@main
struct RestyleCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            Text(CleanFeatureLabel.text + ExcludeFeatureLabel.text)
        }
    }
}
