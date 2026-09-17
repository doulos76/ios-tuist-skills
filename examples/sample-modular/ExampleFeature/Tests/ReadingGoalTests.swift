import Testing
@testable import ExampleFeature

@Test func readingGoalProgressIsBounded() {
    var goal = ReadingGoal(target: 2, completed: 1)

    #expect(goal.progress == 0.5)
    goal.markBookCompleted()
    goal.markBookCompleted()

    #expect(goal.completed == 2)
    #expect(goal.progress == 1)
}
