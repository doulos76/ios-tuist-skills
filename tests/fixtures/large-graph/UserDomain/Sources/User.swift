import CoreNetworking
import CorePersistence

public struct User: Equatable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct UserRepository {
    public init() {}

    public func request(for id: String) -> HTTPRequest {
        HTTPRequest(path: "/users/" + id)
    }

    public func cache(_ user: User) -> Cache {
        var cache = Cache()
        cache.save(user.name, key: user.id)
        return cache
    }
}
