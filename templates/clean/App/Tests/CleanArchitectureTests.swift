import Testing
@testable import App

struct CleanArchitectureTests {
    @Test func domainGreetingStoresItsMessage() {
        #expect(Greeting(message: "Hello") == Greeting(message: "Hello"))
    }

    @Test func dataRepositoryBuildsAGreeting() {
        let repository = InMemoryGreetingRepository()
        #expect(repository.greeting(for: "Data").message == "Hello, Data!")
    }

    @Test func presentationUsesTheRepositoryBoundary() {
        let presenter = GreetingPresenter(repository: StubGreetingRepository())
        #expect(presenter.title(for: "ignored") == "Injected greeting")
    }
}

private struct StubGreetingRepository: GreetingProviding {
    func greeting(for name: String) -> Greeting {
        Greeting(message: "Injected greeting")
    }
}
