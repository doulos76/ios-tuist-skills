import XCTest
@testable import CleanFeature

final class CleanFeatureTests: XCTestCase {
    func testLabel() {
        XCTAssertEqual(CleanFeatureLabel.text, "Clean")
    }
}
