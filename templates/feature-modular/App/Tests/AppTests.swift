import Testing
@testable import App

struct AppTests {
    @Test func rootConfigurationProvidesAName() {
        #expect(AppConfiguration.defaultName == "Tuist")
        _ = AppRootView().body
    }
}
