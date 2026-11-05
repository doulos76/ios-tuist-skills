import Testing
@testable import App

@Test func appTitleIsTrimmed() {
    #expect(AppConfiguration.title == "Large Graph")
}
