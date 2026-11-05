import CoreNetworking
import CorePersistence

public struct Order: Equatable {
    public let items: [String]
    public let totalCents: Int

    public init(items: [String], totalCents: Int) {
        self.items = items
        self.totalCents = totalCents
    }
}

public struct OrderService {
    public init() {}

    public func submitRequest(_ order: Order) -> HTTPRequest {
        HTTPRequest(path: "/orders?count=" + String(order.items.count))
    }

    public func draft(_ order: Order) -> Cache {
        var cache = Cache()
        cache.save(String(order.totalCents), key: "draft-total")
        return cache
    }
}
