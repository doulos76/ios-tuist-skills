import SwiftUI

@main
struct CleanApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    private let presenter = GreetingPresenter(
        repository: InMemoryGreetingRepository()
    )

    var body: some View {
        Text(presenter.title(for: "Tuist"))
            .padding()
    }
}

struct GreetingPresenter {
    private let repository: any GreetingProviding

    init(repository: any GreetingProviding) {
        self.repository = repository
    }

    func title(for name: String) -> String {
        repository.greeting(for: name).message
    }
}
