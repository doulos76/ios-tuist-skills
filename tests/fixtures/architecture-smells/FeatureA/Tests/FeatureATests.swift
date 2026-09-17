import Testing
@testable import FeatureA

@Test func titleUppercasesRawValue() {
    #expect(FeatureATitleFormatter.title(for: "profile") == "PROFILE")
}
