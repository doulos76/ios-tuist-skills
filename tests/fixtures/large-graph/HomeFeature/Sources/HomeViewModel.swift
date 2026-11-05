import CatalogDomain
import CoreAnalytics
import CoreUI

public struct HomeViewModel {
    public init() {}

    public func featuredTitle(for product: Product) -> String {
        _ = Analytics.event("home_featured")
        return product.title
    }

    public var padding: Double {
        Layout.padded(4)
    }
}
