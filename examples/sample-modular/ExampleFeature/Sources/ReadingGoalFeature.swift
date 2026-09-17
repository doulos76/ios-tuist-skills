import SwiftUI

public struct ReadingGoal: Equatable {
    public let target: Int
    public private(set) var completed: Int

    public init(target: Int, completed: Int = 0) {
        self.target = max(1, target)
        self.completed = min(max(0, completed), self.target)
    }

    public var progress: Double {
        Double(completed) / Double(target)
    }

    public mutating func markBookCompleted() {
        completed = min(completed + 1, target)
    }
}

public struct ReadingGoalView: View {
    @State private var goal: ReadingGoal

    public init(goal: ReadingGoal) {
        self.goal = goal
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Weekly reading")
                .font(.title)
            ProgressView(value: goal.progress)
            Text("\(goal.completed) of \(goal.target) books")
            Button("Finished a book") {
                goal.markBookCompleted()
            }
            .disabled(goal.completed == goal.target)
        }
        .padding()
    }
}
