import Testing
@testable import FeatureA

@Suite struct FeatureATests {
    @Test func labelIsStable() {
        #expect(FeatureALabel.text == "FeatureA")
    }
}
