import CatalogDomain
import Testing
@testable import HomeFeature

@Test func featuredTitleUsesTheProductTitle() {
    let product = Product(id: "p1", title: "Lamp", priceCents: 1999)
    #expect(HomeViewModel().featuredTitle(for: product) == "Lamp")
}
