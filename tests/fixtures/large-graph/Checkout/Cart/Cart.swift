import OrderDomain

public struct Cart {
    public private(set) var items: [String] = []
    public private(set) var totalCents = 0

    public init() {}

    public mutating func add(_ item: String, cents: Int) {
        items.append(item)
        totalCents += cents
    }

    public func order() -> Order {
        Order(items: items, totalCents: totalCents)
    }

    public var formattedTotal: String {
        PriceFormatter.format(cents: totalCents)
    }
}
