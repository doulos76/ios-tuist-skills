import XCTest
@testable import ExcludeFeature

final class ExcludeFeatureTests: XCTestCase {
    func testLabel() {
        XCTAssertEqual(ExcludeFeatureLabel.text, "Exclude")
    }
}
