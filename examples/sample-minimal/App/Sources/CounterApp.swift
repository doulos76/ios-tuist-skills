import SwiftUI

@main
struct CounterApp: App {
    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}

struct CounterView: View {
    @State private var counter = Counter()

    var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(counter.value)")
                .font(.title)
            Button("Increment") {
                counter.increment()
            }
            Button("Reset", role: .destructive) {
                counter.reset()
            }
        }
        .padding()
    }
}

struct Counter: Equatable {
    private(set) var value = 0

    mutating func increment() {
        value += 1
    }

    mutating func reset() {
        value = 0
    }
}
