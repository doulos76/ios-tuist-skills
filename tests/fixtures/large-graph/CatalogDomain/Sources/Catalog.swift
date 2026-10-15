import CoreNetworking

public struct Product: Equatable {
    public let id: String
    public let title: String
    public let priceCents: Int

    public init(id: String, title: String, priceCents: Int) {
        self.id = id
        self.title = title
        self.priceCents = priceCents
    }
}

public struct CatalogService {
    public init() {}

    public func searchRequest(_ query: String) -> HTTPRequest {
        HTTPRequest(path: "/catalog/search?q=" + query)
    }
}
