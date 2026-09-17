import Testing
@testable import App

@Test func appProvidesAnInitialProfileName() {
    #expect(AppLaunchConfiguration.profileName == "Taylor")
}
