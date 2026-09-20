import XCTest
@testable import App

final class AppTests: XCTestCase {
    func testAppModuleExposesItsEntryPoint() {
        XCTAssertEqual(String(describing: ScaffoldCandidateApp.self), "ScaffoldCandidateApp")
    }
}
