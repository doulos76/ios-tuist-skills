import CoreNetworking
import Testing
@testable import CatalogDomain

@Test func searchRequestTargetsTheCatalog() {
    #expect(CatalogService().searchRequest("lamp") == HTTPRequest(path: "/catalog/search?q=lamp"))
}
