import Testing
@testable import CoreKit

@Test func titleUppercasesRawValue() {
    #expect(CoreDisplayFormatter.title(for: "profile") == "PROFILE")
}
