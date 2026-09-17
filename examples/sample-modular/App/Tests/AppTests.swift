import Testing
@testable import App

@Test func appStartsWithAReachableWeeklyGoal() {
    let goal = AppConfiguration.weeklyReadingGoal

    #expect(goal.target == 5)
    #expect(goal.completed < goal.target)
}
