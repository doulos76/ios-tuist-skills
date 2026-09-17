import Testing
@testable import App

@Test func greetingTextIsStable() {
    #expect(Greeting.text == "Hello, CI")
}
