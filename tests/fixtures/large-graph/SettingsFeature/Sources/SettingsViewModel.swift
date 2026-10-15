import CoreUI
import UserDomain

public struct SettingsViewModel {
    public init() {}

    public func title(for user: User) -> String {
        "Settings - " + user.name
    }

    public func subscriptionPrice(cents: Int) -> String {
        let dollars = cents / 100
        let remainder = cents % 100
        return "$" + String(dollars) + "." + (remainder < 10 ? "0" : "") + String(remainder)
    }
}
