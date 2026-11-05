import CoreUI
import UserDomain

public struct ProfileViewModel {
    public let user: User

    public init(user: User) {
        self.user = user
    }

    public var title: String {
        user.name
    }

    public var padding: Double {
        Layout.padded(2)
    }
}
