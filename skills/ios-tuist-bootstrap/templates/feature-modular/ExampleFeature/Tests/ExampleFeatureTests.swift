import Testing
@testable import ExampleFeature

struct ExampleFeatureTests {
    @Test func greetingIncludesTheProvidedName() {
        #expect(FeatureGreeting.message(for: "Feature") == "Hello, Feature!")
    }
}
