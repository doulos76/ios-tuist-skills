import Testing
@testable import App

struct AppTests {
    // template smoke test
    @Test func greetingUsedByTheRootViewIsStable() {
        #expect(Greeting.message == "Hello, Tuist")
        _ = ContentView().body
    }
}
