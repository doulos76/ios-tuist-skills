import SwiftUI
import FeatureA
import FeatureB

@main
struct TestTargetCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            Text(FeatureALabel.text + FeatureBLabel.text)
        }
    }
}
