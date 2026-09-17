import Testing
@testable import ProfileFeature

@Test func profileGreetingIncludesTheName() {
    #expect(ProfileFormatter.greeting(for: "Taylor") == "Hello, Taylor")
}
