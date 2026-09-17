import Testing
@testable import SharedUI

@Test func badgeLabelsAreUppercased() {
    #expect(BadgeFormatter.displayText(for: "Member") == "MEMBER")
}
