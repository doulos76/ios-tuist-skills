import ExampleFeature
import SwiftUI

@main
struct SampleModularApp: App {
    var body: some Scene {
        WindowGroup {
            ReadingGoalView(goal: AppConfiguration.weeklyReadingGoal)
        }
    }
}

enum AppConfiguration {
    static let weeklyReadingGoal = ReadingGoal(target: 5, completed: 2)
}
