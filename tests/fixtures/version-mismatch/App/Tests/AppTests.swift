import XCTest
@testable import App

final class AppTests: XCTestCase {
    func testSettingsTitleIsStable() {
        XCTAssertEqual(SettingsTitle.value, "Settings")
    }
}
