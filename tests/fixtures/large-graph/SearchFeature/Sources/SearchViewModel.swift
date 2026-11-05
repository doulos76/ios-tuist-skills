import CatalogDomain
import CoreNetworking
import CoreUI

public struct SearchViewModel {
    private let client = HTTPClient()
    private let catalog = CatalogService()

    public init() {}

    public func requestDescription(for query: String) -> String {
        client.describe(HTTPRequest(path: "/search?q=" + query))
    }

    public func catalogRequest(for query: String) -> HTTPRequest {
        catalog.searchRequest(query)
    }
}
