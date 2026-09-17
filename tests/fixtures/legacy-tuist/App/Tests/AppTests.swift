import XCTest
@testable import App

final class AppTests: XCTestCase {
    func testLoginMessageUsesExistingConvention() {
        XCTAssertEqual(LoginMessage.defaultText, "Welcome back")
    }
}
